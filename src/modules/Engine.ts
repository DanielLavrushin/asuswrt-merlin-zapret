import axios from 'axios';

export enum SubmtActions {
  APPLY = 'zapretui_web_apply',
  START = 'zapretui_web_start',
  STOP = 'zapretui_web_stop',
  RESTART = 'zapretui_web_restart',
  INIT_RESPOSE = 'zapretui_web_initresponse'
}

export class EngineLoadingProgress {
  public progress = 0;
  public message = '';

  constructor(progress?: number, message?: string) {
    if (progress) {
      this.progress = progress;
    }
    if (message) {
      this.message = message;
    }
  }
}

export class EngineTpwsResponse {
  port? = 10180;
  interface?: string;
  interfaces?: string[] = [];
}

export class EngineNfqwsResponse {
  qnum? = 200;
  desync_mark? = 0x40000000;
}

export class EngineResponseConfig {
  public tpws: EngineTpwsResponse = {};
  public nfqws: EngineNfqwsResponse = {};
  public loading?: EngineLoadingProgress;
}

class Engine {
  async getResponse(): Promise<EngineResponseConfig> {
    const response = await axios.get<EngineResponseConfig>('/ext/zapretui/response.json');
    let responseConfig = response.data;
    return responseConfig;
  }

  async executeWithLoadingProgress(action: () => Promise<void>, windowReload = true): Promise<void> {
    let loadingProgress = new EngineLoadingProgress(0, 'Please, wait');
    window.showLoading(null, loadingProgress);

    const progressPromise = this.checkLoadingProgress(loadingProgress, windowReload);

    const actionPromise = action();
    await Promise.all([actionPromise, progressPromise]);
  }

  async checkLoadingProgress(loadingProgress: EngineLoadingProgress, windowReload = true): Promise<void> {
    return new Promise((resolve, reject) => {
      const checkProgressInterval = setInterval(async () => {
        try {
          const response = await this.getResponse();
          if (response.loading) {
            loadingProgress = response.loading;
            window.updateLoadingProgress(loadingProgress);
          } else {
            clearInterval(checkProgressInterval);
            window.hideLoading();
            resolve();
            if (windowReload) {
              window.location.reload();
            }
          }
        } catch (error) {
          clearInterval(checkProgressInterval);
          window.hideLoading();
          reject(new Error('Error while checking loading progress'));
        }
      }, 1000);
    });
  }

  public setCookie = (name: string, val: string): void => {
    const date = new Date();
    const value = val;
    date.setTime(date.getTime() + 365 * 24 * 60 * 60 * 1000);
    document.cookie = name + '=' + value + '; expires=' + date.toUTCString() + '; path=/';
  };

  public getCookie = (name: string): string | undefined => {
    const value = '; ' + document.cookie;
    const parts = value.split('; ' + name + '=');

    if (parts.length === 2) {
      return parts.pop()?.split(';').shift();
    }
  };

  public deleteCookie = (name: string): void => {
    const date = new Date();
    date.setTime(date.getTime() + -1 * 24 * 60 * 60 * 1000);
    document.cookie = name + '=; expires=' + date.toUTCString() + '; path=/';
  };

  private splitPayload(payload: string, chunkSize: number): string[] {
    const chunks: string[] = [];
    let index = 0;
    while (index < payload.length) {
      chunks.push(payload.slice(index, index + chunkSize));
      index += chunkSize;
    }
    return chunks;
  }

  public submit(action: string, payload: object | string | number | null | undefined = undefined, delay = 0): Promise<void> {
    return new Promise((resolve) => {
      const iframeName = 'hidden_frame_' + Math.random().toString(36).substring(2, 9);
      const iframe = document.createElement('iframe');
      iframe.name = iframeName;
      iframe.style.display = 'none';

      document.body.appendChild(iframe);

      const form = document.createElement('form');
      form.method = 'post';
      form.action = '/start_apply.htm';
      form.target = iframeName;

      this.create_form_element(form, 'hidden', 'action_mode', 'apply');
      this.create_form_element(form, 'hidden', 'action_script', action);
      this.create_form_element(form, 'hidden', 'modified', '0');
      this.create_form_element(form, 'hidden', 'action_wait', '');

      const amngCustomInput = document.createElement('input');
      if (payload) {
        const chunkSize = 2048;
        const payloadString = JSON.stringify(payload);
        const chunks = this.splitPayload(payloadString, chunkSize);
        chunks.forEach((chunk: string, idx) => {
          window.zapretui.custom_settings[`zapretui_payload${idx}`] = chunk;
        });

        const customSettings = JSON.stringify(window.zapretui.custom_settings);
        if (customSettings.length > 8 * 1024) {
          alert('Configuration is too large to submit via custom settings.');
          throw new Error('Configuration is too large to submit via custom settings.');
        }

        amngCustomInput.type = 'hidden';
        amngCustomInput.name = 'amng_custom';
        amngCustomInput.value = customSettings;
        form.appendChild(amngCustomInput);
      }

      document.body.appendChild(form);

      iframe.onload = () => {
        document.body.removeChild(form);
        document.body.removeChild(iframe);

        setTimeout(() => {
          resolve();
        }, delay);
      };
      form.submit();
      if (form.contains(amngCustomInput)) {
        form.removeChild(amngCustomInput);
      }
    });
  }

  create_form_element = (form: HTMLFormElement, type: string, name: string, value: string): HTMLInputElement => {
    const input = document.createElement('input');
    input.type = type;
    input.name = name;
    input.value = value;
    form.appendChild(input);
    return input;
  };
}

let engine = new Engine();
export default engine;
