<template>

  <div class="dropdown"
       :class="{'is-active': suggestionsVisible}">
    <div class="dropdown-trigger">
      <input v-model="tag"
             type="text"
             class="tag-input input is-small"
             aria-haspopup="true"
             aria-controls="dropdown-menu"
             @keydown.enter="selectTag"
             @keydown.space="selectTag"
             @keydown.down='focusNextSuggestion'
             @keydown.up='focusPreviousSuggestion'
             @keydown.esc='closeDropdown'
             @input="openDropdown(); tagChanged()"
             ref="tagInput"/>
    </div>
    <div class="dropdown-menu"
         id="dropdown-menu"
         role="menu">
      <div class="dropdown-content">
        <a v-for="(suggestion, index) in matches"
           :class="{'is-active': isSuggestionFocused(index)}"
           @click="suggestionClick(index)"
           :key="index"
           class="dropdown-item">
          {{ suggestion }}
        </a>
      </div>
    </div>
  </div>

</template>

<script>

import DatasetsUtils from '@/assets/DatasetsUtils'
import RequestsUtils from '@/assets/RequestsUtils'

export default {
  name: 'TagAutocompleteInput',

  props: {
    initialTag: {
      type: String,
      default: ''
    },
    clearInputAfterSelection: Boolean,
    autoFocus: Boolean,
    selectionType: {
      type: String,
      validator(val) {
        if (!val) {
          return false
        }
        return ['single', 'multiple'].includes(val.toLowerCase())
      },
      default: 'single'
    }
  },

  watch: {
    initialTag: function (newVal) {
      if (this.tag !== newVal) {
        this.tag = newVal
        this.closeDropdown()
      }
    }
  },

  mounted() {
    ['keyup', 'keydown', 'keypress', 'focus', 'blur'].map(event => {
      this.$refs.tagInput.addEventListener(event, $event => this.$emit(event, $event))
    })
    if (this.autoFocus) {
      this.$refs.tagInput.focus()
    }
  },

  data() {
    return {
      tag: this.initialTag,
      open: false,
      tagsSuggestions: [],
      focusedSuggestionIndex: -1,
      db: 'system',
      key: 'autocomplete',

      apiRoot: DatasetsUtils.ConfAPIRoot,
      apiVersion: DatasetsUtils.ConfAPIVersion,
    }
  },

  computed: {

    // Filtering the tags based on the input
    matches() {
      return this.tagsSuggestions?.filter((str) => {
        return str.includes(this.currentTag.toLowerCase())
      })
    },

    suggestionsVisible() {
      return this.currentTag !== '' && this.matches?.length !== 0 && this.open
    },

    currentTag: {
      get: function () {
        let currentTag
        if (this?.selectionType.toLowerCase() === 'multiple') {
          const tags = this.tag.split(' ')
          currentTag = tags[tags.length - 1].trim()
        } else {
          currentTag = this.tag.trim()
        }
        return currentTag
      },
      set: function (currentTag) {
        if (this.selectionType.toLowerCase() === 'multiple') {
          const tags = this.tag.split(' ')
          tags[tags.length - 1] = currentTag
          this.tag = tags.join(' ')
        } else {
          this.tag = currentTag.trim()
        }
      }
    },

  },

  methods: {

    loadAutocompleteSuggestions() {
      RequestsUtils.sendRequest('GET', `db/${this.db}/k/${this.key}/`)
          .then(response => {
            this.tagsSuggestions = response.data?.tags || []
            this.tagsSuggestions.sort()
          })
          .catch(() => {
            this.createAutocompleteDBKey()
          })
    },

    openDropdown() {
      this.open = true
    },

    tagChanged() {
      this.$emit('tag-changed', this.tag)
    },

    tagSubmitted() {
      this.$emit('tag-submitted', this.tag)
    },

    closeDropdown() {
      this.open = false
    },

    suggestionClick(index) {
      this.focusedSuggestionIndex = index
      this.selectTag()
    },

    async selectTag() {
      if (this.focusedSuggestionIndex !== -1) {
        this.currentTag = this.matches[this.focusedSuggestionIndex]
      } else if (!this.tagsSuggestions.includes(this.currentTag.toLowerCase())) {
        await this.addUnknownTagToDB(this.currentTag)
      }
      this.tagSubmitted()
      this.tagChanged()
      this.focusedSuggestionIndex = -1
      this.$refs.tagInput.focus()
      this.open = false
      if (this.clearInputAfterSelection) {
        this.tag = ''
      }
    },

    focusPreviousSuggestion() {
      if (this.focusedSuggestionIndex > -1)
        this.focusedSuggestionIndex--
    },

    focusNextSuggestion() {
      if (this.focusedSuggestionIndex < this.matches.length - 1)
        this.focusedSuggestionIndex++
    },

    isSuggestionFocused(index) {
      return index === this.focusedSuggestionIndex
    },

    async createAutocompleteDBKey() {
      // if database doesn't exist, create it and wait until it's created
      await RequestsUtils.sendRequest('GET', `db/${this.db}/`)
          .catch(async () => {
            await RequestsUtils.sendRequest('POST', `db/${this.db}/`, {})
          })
      // if key doesn't exist, create it
      RequestsUtils.sendRequest('GET', `db/${this.db}/k/${this.key}/`)
          .catch(() => {
            RequestsUtils.sendRequest('PUT', `db/${this.db}/k/${this.key}/`, {})
          })
    },

    async addUnknownTagToDB(tag) {
      tag = tag.toLowerCase()
      const response = await RequestsUtils.sendRequest('GET', `db/${this.db}/k/${this.key}/`)
      const document = {...{tags: []}, ...response.data}
      document.tags.push(tag)
      this.tagsSuggestions = document.tags || []
      this.tagsSuggestions.sort()
      return RequestsUtils.sendRequest('PUT', `db/${this.db}/k/${this.key}/`, document)
          .then((response) => {
            console.log(`saved tag [${tag}] to database, it will now be available for autocomplete!`)
            return response
          })
          .catch((error) => {
            console.log(`failed saving tag [${tag}]`)
            throw error
          })
    },

  },

  created() {
    this.loadAutocompleteSuggestions()
  }
}
</script>

<style scoped>
.dropdown, .dropdown-trigger, .dropdown-menu {
  width: 100%
}
</style>
