<template>
  <div class="card">
    <div class="card-content">
      <div class="media">
        <div class="media-content">
          <div class="columns">
            <div class="column">
              <div class="field is-grouped">
                <input class="input is-small is-fullwidth document-name"
                       type="text"
                       placeholder="Document name"
                       v-model="selectedDoc.name">
              </div>
              <p class="subtitle is-6 has-text-grey document-id"
                 title="Document ID">
                {{ selectedDoc.id }}
              </p>
            </div>
            <div class="column"></div>
            <div class="column">
            </div>
          </div>
        </div>
      </div>

      <div class="content">
        <hr/>
        <div class="sequence-wrapper">
          <div v-for="(sequence, sequenceIndex) in localDoc.sequence"
               :key="sequenceIndex"
               class="sequence">
            <div class="sequence-options">
              <table class="sequence-option is-size-7">
                <thead>
                <tr>
                  <th class="is-48-px"></th>
                  <th class="is-120-px">
                    <label class="label is-small">Method</label>
                  </th>
                  <th>
                    <label class="label is-small">Path</label>
                  </th>
                  <th class="is-80-px">
                    <a class="has-text-grey-dark is-small is-pulled-right"
                       title="Add new sequence option"
                       @click="addSequenceEntryOption(sequenceIndex)">
                      <span class="icon is-small"><i class="fas fa-plus"></i></span>
                    </a>
                  </th>
                </tr>
                </thead>
                <tbody>
                <tr v-for="(option, optionIndex) in sequence"
                    :key="optionIndex">
                  <td class="is-size-7 is-48-px has-text-centered has-text-grey-light options-relation">
                    <span v-if="optionIndex !== 0" class="is-small">
                      OR
                    </span>
                  </td>
                  <td class="is-120-px">
                    <div class="select">
                      <select v-model="option[0]" @change="emitDocUpdate">
                        <option v-for="method in methodNames" :key="method" :value="method">{{ method }}</option>
                      </select>
                    </div>
                  </td>
                  <td>
                    <input class="input is-small" v-model="option[1]" @input="emitDocUpdate"/>
                  </td>
                  <td class="is-80-px">
                    <a class="is-small has-text-grey"
                       title="Remove option"
                       @click="removeSequenceEntryOption(sequenceIndex, optionIndex)">
                      remove
                    </a>
                  </td>
                </tr>
                </tbody>
              </table>
            </div>
            <div v-if="localDoc.sequence.length > 1 && sequenceIndex !== localDoc.sequence.length - 1"
                 class="control is-expanded relation-wrapper">
              <span class="tag is-small is-relative">
                THEN
              </span>
            </div>
          </div>
          <button class="button is-small new-sequence-button"
                  @click="addSequenceEntry()">
            Create new sequence section
          </button>
        </div>
        <span class="is-family-monospace has-text-grey-lighter">{{ apiPath }}</span>
      </div>
    </div>
  </div>
</template>

<script>

export default {
  name: 'FlowControl',
  props: {
    selectedDoc: Object,
    apiPath: String
  },
  data() {
    return {
      emptySequenceOption: ['GET','/'],
      methodNames: ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'CONNECT', 'OPTIONS', 'TRACE', 'PATCH']
    }
  },
  computed: {
    localDoc() {
      return JSON.parse(JSON.stringify(this.selectedDoc))
    },
  },
  methods: {
    emitDocUpdate() {
      this.$emit('update', this.localDoc)
    },

    addSequenceEntry() {
      this.localDoc.sequence.push([this.emptySequenceOption])
      this.emitDocUpdate()
    },

    removeSequenceEntry(sequenceIndex) {
      this.localDoc.sequence.splice(sequenceIndex, 1)
      this.emitDocUpdate()
    },

    addSequenceEntryOption(sequenceIndex) {
      const sequenceEntry = this.localDoc.sequence[sequenceIndex]
      sequenceEntry.push(this.emptySequenceOption)
      this.emitDocUpdate()
    },

    removeSequenceEntryOption(sequenceIndex, optionIndex) {
      const sequenceEntry = this.localDoc.sequence[sequenceIndex]
      sequenceEntry.splice(optionIndex, 1)
      if (sequenceEntry.length === 0) {
        this.removeSequenceEntry(sequenceIndex)
      }
      this.emitDocUpdate()
    },
  },
}
</script>

<style scoped>

.sequence-options {
  margin-bottom: 1rem
}

.sequence-option .select, .sequence-option select {
  width: 100%
}

.relation-wrapper {
  text-align: center;
  margin-bottom: 1rem;
}

.relation-wrapper:before {
  content: '';
  position: absolute;
  top: 50%;
  left: 0;
  border-top: 1px solid black;
  background: black;
  width: 100%;
  transform: translateY(-50%);
}

.is-48-px {
  min-width: 40px;
  max-width: 40px;
  width: 48px;
}

.is-80-px {
  min-width: 80px;
  max-width: 80px;
  width: 80px;
}

.is-120-px {
  min-width: 120px;
  max-width: 120px;
  width: 120px;
}

</style>
