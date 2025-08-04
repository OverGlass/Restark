const {
  Provider,
  Contract,
  Account,
  ec,
  json,
  stark,
  uint256,
  shortString,
} = require("starknet");
const fs = require("fs");
const path = require("path");
const winston = require("winston");
const schedule = require("node-schedule");
require("dotenv").config();

// Configure logger
const logger = winston.createLogger({
  level: "info",
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json(),
  ),
  transports: [
    new winston.transports.File({ filename: "error.log", level: "error" }),
    new winston.transports.File({ filename: "combined.log" }),
    new winston.transports.Console({
      format: winston.format.simple(),
    }),
  ],
});

// Configuration
const config = {
  // Network configuration
  rpcUrl: process.env.RPC_URL || "https://starknet-mainnet.public.blastapi.io",

  // Contract addresses
  restarkeContract: process.env.RESTARKE_CONTRACT,

  // Account configuration
  accountAddress: process.env.ACCOUNT_ADDRESS,
  privateKey: process.env.PRIVATE_KEY,

  // Automation settings
  cronSchedule: process.env.CRON_SCHEDULE || "0 */12 * * *", // Every 12 hours by default
  minRewardThreshold: process.env.MIN_REWARD_THRESHOLD || "1000000000000000000", // 1 STARK
  maxRetries: parseInt(process.env.MAX_RETRIES) || 3,
  retryDelay: parseInt(process.env.RETRY_DELAY) || 60000, // 1 minute

  // Monitoring
  webhookUrl: process.env.WEBHOOK_URL, // Optional Discord/Slack webhook
};

// Validate configuration
function validateConfig() {
  const required = ["restarkeContract", "accountAddress", "privateKey"];
  const missing = required.filter((key) => !config[key]);

  if (missing.length > 0) {
    throw new Error(`Missing required configuration: ${missing.join(", ")}`);
  }
}

// Initialize Starknet provider and account
async function initializeStarknet() {
  try {
    const provider = new Provider({ sequencer: { baseUrl: config.rpcUrl } });

    const account = new Account(
      provider,
      config.accountAddress,
      config.privateKey,
    );

    // Load contract ABI
    const contractAbi = JSON.parse(
      fs.readFileSync(
        path.join(
          __dirname,
          "../contracts/target/dev/restarke_Restarke.contract_class.json",
        ),
        "utf8",
      ),
    ).abi;

    const contract = new Contract(
      contractAbi,
      config.restarkeContract,
      provider,
    );

    // Connect contract to account for write operations
    contract.connect(account);

    return { provider, account, contract };
  } catch (error) {
    logger.error("Failed to initialize Starknet:", error);
    throw error;
  }
}

// Send webhook notification
async function sendNotification(message, isError = false) {
  if (!config.webhookUrl) return;

  try {
    const color = isError ? 0xff0000 : 0x00ff00;
    const payload = {
      embeds: [
        {
          title: "Restarke Keeper",
          description: message,
          color: color,
          timestamp: new Date().toISOString(),
        },
      ],
    };

    await fetch(config.webhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
  } catch (error) {
    logger.error("Failed to send notification:", error);
  }
}

// Check pending rewards
async function checkPendingRewards(contract) {
  try {
    // Get configuration
    const configResult = await contract.get_config();
    const [stakingContract, starkToken, stakerAddress] = configResult;

    // Load staking contract ABI (you'll need to add this)
    // For now, we'll assume rewards can be checked via the staking contract
    // In production, you'd need the actual staking contract ABI

    logger.info("Checking pending rewards...");
    // This is a placeholder - implement actual reward checking logic
    return uint256.bnToUint256(config.minRewardThreshold);
  } catch (error) {
    logger.error("Failed to check pending rewards:", error);
    throw error;
  }
}

// Execute auto-restake
async function executeAutoRestake(contract, retryCount = 0) {
  try {
    logger.info("Executing auto-restake...");

    // Call execute_auto_restake
    const tx = await contract.execute_auto_restake();

    logger.info(`Transaction submitted: ${tx.transaction_hash}`);

    // Wait for transaction confirmation
    const receipt = await contract.provider.waitForTransaction(
      tx.transaction_hash,
    );

    if (receipt.status === "ACCEPTED_ON_L2") {
      // Parse events to get the amount restaked
      const events = receipt.events || [];
      let amountRestaked = "0";

      for (const event of events) {
        if (
          event.keys[0] ===
          stark.hash.getSelectorFromName("AutoRestakeExecuted")
        ) {
          // Assuming the amount is in the event data
          amountRestaked = event.data[1] || "0";
          break;
        }
      }

      const message = `Auto-restake successful! Amount restaked: ${amountRestaked} wei`;
      logger.info(message);
      await sendNotification(message);

      return {
        success: true,
        amount: amountRestaked,
        txHash: tx.transaction_hash,
      };
    } else {
      throw new Error(`Transaction failed with status: ${receipt.status}`);
    }
  } catch (error) {
    logger.error(`Auto-restake failed (attempt ${retryCount + 1}):`, error);

    if (retryCount < config.maxRetries) {
      logger.info(`Retrying in ${config.retryDelay / 1000} seconds...`);
      await new Promise((resolve) => setTimeout(resolve, config.retryDelay));
      return executeAutoRestake(contract, retryCount + 1);
    }

    const errorMessage = `Auto-restake failed after ${config.maxRetries} attempts: ${error.message}`;
    await sendNotification(errorMessage, true);
    throw error;
  }
}

// Main keeper function
async function runKeeper() {
  try {
    logger.info("Starting keeper run...");

    const { provider, account, contract } = await initializeStarknet();

    // Check if it's worth executing (optional)
    const pendingRewards = await checkPendingRewards(contract);
    const threshold = BigInt(config.minRewardThreshold);

    // For now, always execute. In production, you might want to check
    // if pending rewards exceed threshold
    /*
    if (BigInt(pendingRewards) < threshold) {
      logger.info(`Pending rewards below threshold. Skipping this run.`);
      return;
    }
    */

    // Execute auto-restake
    const result = await executeAutoRestake(contract);

    logger.info("Keeper run completed successfully", result);
  } catch (error) {
    logger.error("Keeper run failed:", error);
    await sendNotification(`Keeper run failed: ${error.message}`, true);
  }
}

// Health check endpoint (optional)
function startHealthCheck() {
  const express = require("express");
  const app = express();
  const port = process.env.HEALTH_CHECK_PORT || 3000;

  app.get("/health", (req, res) => {
    res.json({
      status: "healthy",
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    });
  });

  app.listen(port, () => {
    logger.info(`Health check endpoint listening on port ${port}`);
  });
}

// Main function
async function main() {
  try {
    logger.info("Restarke Keeper starting...");

    // Validate configuration
    validateConfig();

    // Start health check endpoint
    if (process.env.ENABLE_HEALTH_CHECK === "true") {
      startHealthCheck();
    }

    // Run immediately on startup
    if (process.env.RUN_ON_STARTUP !== "false") {
      await runKeeper();
    }

    // Schedule periodic runs
    const job = schedule.scheduleJob(config.cronSchedule, async () => {
      logger.info("Scheduled keeper run starting...");
      await runKeeper();
    });

    logger.info(`Keeper scheduled with cron pattern: ${config.cronSchedule}`);
    await sendNotification("Restarke Keeper started successfully");

    // Handle graceful shutdown
    process.on("SIGTERM", () => {
      logger.info("SIGTERM received, shutting down gracefully...");
      job.cancel();
      process.exit(0);
    });

    process.on("SIGINT", () => {
      logger.info("SIGINT received, shutting down gracefully...");
      job.cancel();
      process.exit(0);
    });
  } catch (error) {
    logger.error("Fatal error:", error);
    await sendNotification(`Keeper failed to start: ${error.message}`, true);
    process.exit(1);
  }
}

// Run the keeper
if (require.main === module) {
  main();
}

module.exports = { runKeeper, executeAutoRestake };
