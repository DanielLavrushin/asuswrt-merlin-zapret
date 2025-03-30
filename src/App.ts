import { createApp } from 'vue';
import App from './App.vue';

window.scrollTo = () => {};

document.addEventListener('DOMContentLoaded', () => {
  createApp(App).mount('#vue-app');
});
