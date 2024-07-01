import axios from "axios";

interface Config {
  url: string;
  concurrency: number;
  intervalMS: number;
  duration: number; // in seconds
}

const config: Config = {
  url: "http://amit-lb-800122419.us-east-1.elb.amazonaws.com/health",
  concurrency: 3,
  intervalMS: 400, // 400ms between each batch
  duration: 300, // run for 300 seconds
};

const sendRequest = async () => {
  try {
    const response = await axios.get(config.url, { timeout: 3000 });
    console.log(`Status: ${response.status}, Data: ${response.data}`);
  } catch (error) {
    console.error(`Error: ${error}`);
  }
};

const runLoadTest = () => {
  const endTime = Date.now() + config.duration * 1000;
  const intervalId = setInterval(() => {
    if (Date.now() >= endTime) {
      clearInterval(intervalId);
      console.log("Load test completed");
      return;
    }
    for (let i = 0; i < config.concurrency; i++) {
      sendRequest();
    }
  }, config.intervalMS);
};

runLoadTest();
