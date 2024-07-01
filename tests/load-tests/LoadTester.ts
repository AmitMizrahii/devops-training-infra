import axios from "axios";
import { pino, Logger } from "pino";

export interface LoadTestConfig {
  getURLs: Array<string>;
  concurrencyRequestsNum: number;
  intervalMS: number;
  duration: number;
  requestTimeout: number;
}

export class LoadTester {
  private config: LoadTestConfig;
  private logger: Logger;

  constructor(config: LoadTestConfig) {
    this.logger = pino({ name: "LOAD-TESTER", msgPrefix: "LOAD_TESTER" });
    this.validateConfig(config);
    this.config = config;
  }

  private validateConfig(config: LoadTestConfig) {
    if (config.concurrencyRequestsNum <= 0) {
      this,
        this.logger.error(
          `concurrencyRequestsNum field must be at least 1, but the actual value is: ${config.concurrencyRequestsNum}`
        );
      throw new Error("concurrencyRequestsNum must be at least 1");
    }

    if (config.duration <= 0) {
      this,
        this.logger.error(
          `duration field must be at graeter then 0, but the actual value is: ${config.duration}`
        );
      throw new Error("duration must be greater then 0");
    }

    if (config.getURLs.length === 0) {
      this, this.logger.error(`getURLs field  must contain at least one url`);
      throw new Error("getURLs must contain at least one url");
    }
  }
  private sendGetRequests = async (url: string) => {
    try {
      const response = await axios.get(url, {
        timeout: this.config.requestTimeout,
      });
      this.logger.info(`Status: ${response.status}, Data: ${response.data}`);
    } catch (error) {
      this.logger.error(`Error: ${error}`);
    }
  };

  public runLoadTest = () => {
    const endTime = Date.now() + this.config.duration * 1000;
    const intervalId = setInterval(() => {
      if (Date.now() >= endTime) {
        clearInterval(intervalId);
        this.logger.info("Load test completed");
        return;
      }
      for (let index = 0; index < this.config.concurrencyRequestsNum; index++) {
        this.sendGetRequests(this.getRandomUrl());
      }
    }, this.config.intervalMS);
  };

  private getRandomUrl(): string {
    const randomIndex = Math.floor(Math.random() * this.config.getURLs.length);
    return this.config.getURLs[randomIndex];
  }
}
