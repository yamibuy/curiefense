<template>
  <div class="response-actions">
    <label v-if="labelSeparatedLine && label"
           class="label is-small is-size-7 has-text-left form-label">
      {{ label }}
    </label>
    <div class="columns mb-0 is-multiline"
         :class="{'wide-columns': wideColumns}">
      <div v-if="!labelSeparatedLine && label"
           class="column is-2">
        <label class="label is-small has-text-left form-label">{{ label }}</label>
      </div>
      <div class="column"
      :class="{'is-10': isSingleInputColumn}">
        <div class="control select is-fullwidth is-small" v-if="action">
          <select v-model="action.type">
            <option v-for="(value, id) in options" :value="id" :key="id">{{ value.title }}</option>
          </select>
        </div>
      </div>
      <div v-if="isSingleInputColumn"
           class="column is-2">
      </div>
      <div class="column"
           :class="{'is-10': isSingleInputColumn}">
        <p class="control is-fullwidth">
          <input
              v-if="action && (action.type === 'response' || action.type === 'redirect')"
              class="input is-small"
              type="text"
              v-model="action.params.status"
              placeholder="Status code">
          <input
              v-if="action && action.type === 'ban'"
              class="input is-small"
              type="text"
              v-model="action.params.ttl"
              placeholder="Duration">
          <input
              v-if="action && action.type === 'request_header'"
              class="input is-small"
              type="text"
              v-model="action.params.headers"
              placeholder="Header">
        </p>
      </div>
      <template v-if="action && (action.type === 'response' || action.type === 'redirect')">
        <div v-if="!labelSeparatedLine && label"
             class="column is-2">
        </div>
        <div class="column"
        :class="{'is-10': !labelSeparatedLine && label}">
          <div v-if="action.type === 'response'"
               class="control is-fullwidth">
              <textarea
                  v-model="action.params.content"
                  class="textarea is-small"
                  rows="2"
                  placeholder="Response body">
              </textarea>
          </div>
          <div v-if="action.type === 'redirect'"
               class="control is-fullwidth">
            <p>
              <input
                  class="input is-small"
                  type="text"
                  v-model="action.params.location"
                  placeholder="Location">
            </p>
          </div>
        </div>
      </template>
    </div>
    <div v-if="action && (action.type === 'response' || action.type === 'redirect')"
         :class="{'wide-columns': wideColumns}"
         class="columns mb-0">

    </div>
    <div class="content" v-if="action && action.type === 'ban' && action.params.action">
      <response-action :action.sync="action.params.action"
                       :label-separated-line="labelSeparatedLine"
                       :wide-columns="wideColumns"
                       :is-single-input-column="isSingleInputColumn"
                    caption="Ban action"
                    :ignore="['ban']"/>
    </div>
  </div>
</template>

<script>
import DatasetsUtils from '@/assets/DatasetsUtils'

export default {
  name: 'ResponseAction',
  props: {
    action: Object,
    caption: String,
    ignore: Array,
    labelSeparatedLine: Boolean,
    wideColumns: Boolean,
    isSingleInputColumn: Boolean,
  },

  data() {
    const ResponseActions = DatasetsUtils.ResponseActions
    const availableActions = {}
    Object.keys(ResponseActions).forEach(actionType => {
      availableActions[actionType] = {
        type: actionType,
        params: ResponseActions[actionType].params
            ? {...ResponseActions[actionType].params}
            : {}
      }
    })
    const options = this.ld.pickBy({...ResponseActions}, (value, key) => {
      return !this.ignore || !this.ignore.includes(key)
    })
    return {
      options,
      selectedAction: this.action,
      availableActions,
      label: this.caption || 'Action',
      ignoreActions: this.ignore || []
    }
  },
  mounted() {
    this.normalizeAction()
  },
  methods: {
    sendUpdate() {
      this.$emit('change', {...this.selectedAction}, this.index)
    },

    normalizeAction() {
      // adding necessary fields to selectedDoc.action field
      if (!this.action) {
        return
      }
      if (!this.action.params) {
        this.$set(this.action, 'params', {})
      }
      if (!this.action.params.action) {
        this.$set(this.action.params, 'action', {type: 'default', params: {}})
      }
    },
  },
  watch: {
    action() {
      this.normalizeAction()
    }
  }
}
</script>
<style scoped lang="scss">

.response-actions .column.additional {
  padding-top: 0;
}

.wide-columns {
  & .column:first-child {
    padding-left: 0
  }

  & .column:last-child {
    padding-right: 0
  }
}

</style>
