import { LoadTestConfig, LoadTester } from "./LoadTester";

const config: LoadTestConfig = {
  getURLs: ["http://amit-lb-800122419.us-east-1.elb.amazonaws.com/health"],
  concurrencyRequestsNum: 3,
  intervalMS: 400, // 400ms between each batch
  duration: 300, // run for 300 seconds
  requestTimeout: 5000,
};

const tester = new LoadTester(config);

tester.runLoadTest();
