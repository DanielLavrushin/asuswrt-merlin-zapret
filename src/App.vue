<template>
  <asus-top-banner />
  <asus-loading />
  <main-form />
  <asus-footer />
</template>

<script lang="ts">
  import { defineComponent } from 'vue';

  import AsusTopBanner from './components/asus/TopBanner.vue';
  import AsusLoading from './components/asus/Loading.vue';
  import AsusFooter from './components/asus/Footer.vue';
  import MainForm from './components/MainForm.vue';

  export default defineComponent({
    name: 'App',
    components: { AsusTopBanner, AsusLoading, AsusFooter, MainForm },
    setup() {
      return {};
    }
  });
</script>

<style lang="scss" scoped></style>
