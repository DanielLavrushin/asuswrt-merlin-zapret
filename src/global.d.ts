import { SubmtActions, EngineLoadingProgress } from './modules/Engine';

interface UiGlobal {
  commands: SubmtActions;
  custom_settings: UiCustomSettings;
  language: string;
}
interface UiCustomSettings {
  [key: string]: string;
}

declare global {
  interface Window {
    zapretui: UiGlobal;
    confirm: (message?: string) => boolean;
    hint: (message: string) => void;
    overlib: (message: string) => void;
    show_menu: () => void;
    showLoading: (delay?: number | null, flag?: string | EngineLoadingProgress) => void;
    updateLoadingProgress: (progress?: EngineLoadingProgress) => void;
    hideLoading: () => void;
    LoadingTime: (seconds: number, flag?: string) => void;
    showtext: (element: HTMLElement | null, text: string) => void;
    y: number;
    progress: number;
  }
}

export {};
