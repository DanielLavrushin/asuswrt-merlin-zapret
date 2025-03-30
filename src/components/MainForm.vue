<template>
  <form method="post" name="form" action="/start_apply.htm" target="hidden_frame">
    <input type="hidden" name="current_page" :value="page" />
    <input type="hidden" name="next_page" :value="page" />
    <input type="hidden" name="group_id" value="" />
    <input type="hidden" name="modified" value="0" />
    <input type="hidden" name="action_mode" value="apply" />
    <input type="hidden" name="action_wait" value="5" />
    <input type="hidden" name="first_time" value="" />
    <input type="hidden" name="action_script" value="" />
    <input type="hidden" name="amng_custom" value="" />
    <table class="content" align="center" cellpadding="0" cellspacing="0">
      <tbody>
        <tr>
          <td width="17">&nbsp;</td>
          <td valign="top" width="202">
            <asus-main-menu />
            <asus-sub-menu />
          </td>
          <td valign="top">
            <asus-tab-menu />
            <table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
              <tbody>
                <tr>
                  <td valign="top">
                    <table width="760px" border="0" cellpadding="4" cellspacing="0" id="FormTitle" class="FormTitle">
                      <tbody>
                        <tr bgcolor="#4D595D">
                          <td valign="top">
                            <div class="formfontdesc">
                              <div>&nbsp;</div>
                              <div class="formfonttitle" style="text-align: center">Zapret UI</div>
                              <div id="formfontdesc" class="formfontdesc"></div>
                              <div style="margin: 10px 0 10px 5px" class="splitLine"></div>
                              <table class="FormTable" style="width: 100%">
                                <thead>
                                  <tr>
                                    <td colspan="2">
                                      {{ $t('com.MainForm.title') }}
                                      <hint v-html="$t('components.MainForm.hint_title')"></hint>
                                    </td>
                                  </tr>
                                </thead>
                                <tbody>
                                  <tr>
                                    <th>{{ $t('com.MainForm.control') }}</th>
                                    <td>
                                      <span class="row-buttons">
                                        <a class="button_gen button_gen_small" href="#" @click.prevent="start">{{ $t('global.start') }} </a>
                                        <a class="button_gen button_gen_small" href="#" @click.prevent="stop">{{ $t('global.stop') }}</a>
                                      </span>
                                    </td>
                                  </tr>
                                  <tr>
                                    <th>{{ $t('com.MainForm.interface') }}</th>
                                    <td>
                                      <select v-model="response.tpws.interface" class="input_option">
                                        <option v-for="opt in response.tpws.interfaces" :key="opt" :value="opt">
                                          {{ opt }}
                                        </option>
                                      </select>
                                    </td>
                                  </tr>
                                  <tr>
                                    <th>{{ $t('com.MainForm.port') }}</th>
                                    <td>
                                      <input type="number" v-model="response.tpws.port" class="input_6_table" maxlength="5" placeholder="port" onkeypress="return validator.isNumber(this,event);" />
                                    </td>
                                  </tr>
                                  <tr>
                                    <th>{{ $t('com.MainForm.nfqNum') }}</th>
                                    <td>
                                      <input type="number" v-model="response.nfqws.qnum" class="input_25_table" placeholder="200" />
                                    </td>
                                  </tr>
                                  <tr>
                                    <th>{{ $t('com.MainForm.desyncMark') }}</th>
                                    <td>
                                      <input v-model="response.nfqws.desync_mark" class="input_25_table" placeholder="0x40000000" />
                                    </td>
                                  </tr>
                                </tbody>
                              </table>
                              <div class="apply_gen">
                                <input class="button_gen" @click.prevent="apply_settings()" type="button" :value="$t('global.apply')" />
                              </div>
                            </div>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
      </tbody>
    </table>
  </form>
</template>
<script lang="ts">
  import { defineComponent, inject, Ref } from 'vue';

  import AsusMainMenu from './asus/MainMenu.vue';
  import AsusTabMenu from './asus/TabMenu.vue';
  import AsusSubMenu from './asus/SubMenu.vue';

  import Hint from './../Hint.vue';

  import engine, { EngineResponseConfig, SubmtActions } from '../modules/Engine';

  export default defineComponent({
    name: 'MainForm',
    components: {
      AsusMainMenu,
      AsusTabMenu,
      AsusSubMenu,
      Hint
    },
    props: {
      response: {
        type: EngineResponseConfig,
        required: true,
        default: () => new EngineResponseConfig()
      }
    },
    setup(props: { response: EngineResponseConfig }) {
      const uiResponse = inject<Ref<EngineResponseConfig>>('uiResponse')!;

      const apply_settings = async () => {
        await engine.executeWithLoadingProgress(async () => {
          console.log('apply_settings', props.response);
          await engine.submit(SubmtActions.APPLY, props.response);
        });
      };

      const start = async () => {
        await engine.executeWithLoadingProgress(async () => {
          await engine.submit(SubmtActions.START);
          uiResponse.value = await engine.getResponse();
        });
      };

      const stop = async () => {
        await engine.executeWithLoadingProgress(async () => {
          await engine.submit(SubmtActions.STOP);
          uiResponse.value = await engine.getResponse();
        });
      };

      return {
        page: window.location.pathname.substring(1),
        response: uiResponse,
        apply_settings,
        start,
        stop
      };
    }
  });
</script>
