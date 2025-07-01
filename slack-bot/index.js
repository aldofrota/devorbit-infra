const { App } = require("@slack/bolt");
const { exec } = require("child_process");
const { promisify } = require("util");
const cron = require("node-cron");
const path = require("path");

const execAsync = promisify(exec);

// Configuração do app Slack
const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  signingSecret: process.env.SLACK_SIGNING_SECRET,
  socketMode: true,
  appToken: process.env.SLACK_APP_TOKEN,
});

// Função para gerar hash único
function generateHash() {
  return Math.random().toString(36).substring(2, 8);
}

// Função para executar comando e retornar resultado
async function runCommand(command, cwd = process.cwd()) {
  try {
    const { stdout, stderr } = await execAsync(command, { cwd });
    if (stderr) {
      console.warn("Stderr:", stderr);
    }
    return { success: true, output: stdout };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

// Função para criar ambiente
async function createEnvironment(
  hash,
  frontendImage,
  backendImage,
  ssoImage,
  ttl = 2
) {
  const namespace = `devorbit-${hash}`;
  const domain = `${hash}.127.0.0.1.nip.io`;

  console.log(`🚀 Criando ambiente ${namespace}...`);

  // 1. Executar Terraform
  const terraformResult = await runCommand(
    `terraform apply -auto-approve -var="hash=${hash}" -var="ttl_hours=${ttl}" -var="frontend_image=${frontendImage}" -var="backend_image=${backendImage}" -var="sso_image=${ssoImage}"`,
    path.join(process.cwd(), "terraform")
  );

  if (!terraformResult.success) {
    throw new Error(`Erro no Terraform: ${terraformResult.error}`);
  }

  // 2. Deploy dos serviços com Helm
  const helmCommands = [
    `helm upgrade --install frontend ./charts/frontend --namespace ${namespace} --set image.repository=${
      frontendImage.split(":")[0]
    } --set image.tag=${
      frontendImage.split(":")[1] || "latest"
    } --set ingress.hosts[0].host=${domain}`,
    `helm upgrade --install backend ./charts/backend --namespace ${namespace} --set image.repository=${
      backendImage.split(":")[0]
    } --set image.tag=${backendImage.split(":")[1] || "latest"}`,
    `helm upgrade --install sso ./charts/sso --namespace ${namespace} --set image.repository=${
      ssoImage.split(":")[0]
    } --set image.tag=${ssoImage.split(":")[1] || "latest"}`,
  ];

  for (const command of helmCommands) {
    const result = await runCommand(command);
    if (!result.success) {
      throw new Error(`Erro no Helm: ${result.error}`);
    }
  }

  // 3. Aguardar pods ficarem prontos
  await runCommand(
    `kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=frontend -n ${namespace} --timeout=300s`
  );
  await runCommand(
    `kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=backend -n ${namespace} --timeout=300s`
  );
  await runCommand(
    `kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=sso -n ${namespace} --timeout=300s`
  );

  // 4. Executar seed de dados
  const seedResult = await runCommand(`./scripts/seed.sh ${namespace} ${hash}`);
  if (!seedResult.success) {
    console.warn("Aviso: Erro no seed de dados:", seedResult.error);
  }

  return {
    namespace,
    domain,
    hash,
  };
}

// Comando /deploy
app.command("/deploy", async ({ command, ack, respond }) => {
  await ack();

  try {
    const args = command.text.split(" ");
    const params = {};

    // Parse dos argumentos
    for (const arg of args) {
      if (arg.includes("=")) {
        const [key, value] = arg.split("=");
        params[key] = value;
      }
    }

    // Valores padrão
    const hash = generateHash();
    const frontendImage = params.frontend || "devorbit/frontend:latest";
    const backendImage = params.backend || "devorbit/backend:latest";
    const ssoImage = params.sso || "devorbit/sso:latest";
    const ttl = parseInt(params.ttl) || 2;

    await respond({
      text: `🚀 Criando ambiente DevOrbit...\nHash: \`${hash}\`\nAguarde um momento...`,
    });

    const result = await createEnvironment(
      hash,
      frontendImage,
      backendImage,
      ssoImage,
      ttl
    );

    await respond({
      text:
        `✅ *Ambiente criado com sucesso!*\n\n` +
        `🌐 *URL:* https://${result.domain}\n` +
        `📧 *Usuário:* user@devorbit.com\n` +
        `🔑 *Senha:* dev123\n` +
        `⏰ *Expira em:* ${ttl}h\n` +
        `🏷️ *Hash:* \`${hash}\``,
      unfurl_links: false,
    });
  } catch (error) {
    console.error("Erro ao criar ambiente:", error);
    await respond({
      text: `❌ *Erro ao criar ambiente:*\n\`\`\`${error.message}\`\`\``,
    });
  }
});

// Comando /status
app.command("/status", async ({ command, ack, respond }) => {
  await ack();

  try {
    const result = await runCommand(
      'kubectl get namespaces -l devorbit/hash -o jsonpath=\'{range .items[*]}{.metadata.name}{"\\t"}{.metadata.labels.devorbit/ttl}{"\\t"}{.metadata.labels.devorbit/created-at}{"\\n"}{end}\''
    );

    if (!result.success) {
      throw new Error(result.error);
    }

    if (!result.output.trim()) {
      await respond({
        text: "✅ Nenhum ambiente DevOrbit ativo encontrado.",
      });
      return;
    }

    let statusText = "📊 *Ambientes DevOrbit Ativos:*\n\n";
    const environments = result.output.trim().split("\n");

    for (const env of environments) {
      if (!env) continue;

      const [namespace, ttl, created] = env.split("\t");
      const hash = namespace.replace("devorbit-", "");
      const domain = `${hash}.127.0.0.1.nip.io`;

      statusText += `🏷️ *${hash}*\n`;
      statusText += `   🌐 https://${domain}\n`;
      statusText += `   ⏰ TTL: ${ttl}h\n`;
      statusText += `   📅 Criado: ${created}\n\n`;
    }

    await respond({
      text: statusText,
      unfurl_links: false,
    });
  } catch (error) {
    console.error("Erro ao buscar status:", error);
    await respond({
      text: `❌ *Erro ao buscar status:*\n\`\`\`${error.message}\`\`\``,
    });
  }
});

// Comando /cleanup
app.command("/cleanup", async ({ command, ack, respond }) => {
  await ack();

  try {
    const result = await runCommand("./scripts/cleanup.sh");

    if (!result.success) {
      throw new Error(result.error);
    }

    await respond({
      text: `✅ *Limpeza executada:*\n\`\`\`${result.output}\`\`\``,
    });
  } catch (error) {
    console.error("Erro na limpeza:", error);
    await respond({
      text: `❌ *Erro na limpeza:*\n\`\`\`${error.message}\`\`\``,
    });
  }
});

// Cron job para limpeza automática (a cada hora)
cron.schedule("0 * * * *", async () => {
  console.log("🕐 Executando limpeza automática...");
  try {
    await runCommand("./scripts/cleanup.sh");
    console.log("✅ Limpeza automática concluída");
  } catch (error) {
    console.error("❌ Erro na limpeza automática:", error);
  }
});

// Iniciar o app
(async () => {
  await app.start();
  console.log("🤖 Bot DevOrbit iniciado!");
})();
