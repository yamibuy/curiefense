<template>
  <div class="card">
    <div class="card-content">
      <div class="content">
        <div class="columns">
          <div class="column is-4" style="border-right:solid 2px #f8f8f8; ">
            <div class="field">
              <label class="label is-small">Name</label>
              <div class="control">
                <input class="input is-small" placeholder="list name" v-model="selectedDoc.name"
                       :readonly="readonly"/>
              </div>
              <p class="subtitle is-7 has-text-grey">{{ selectedDoc.id + '\t|\t' + listTotalEntries + ' entries.' }}</p>
            </div>
            <div class="field">
              <a v-if="selectedDoc && selectedDoc.source && selectedDoc.source.indexOf('http') === 0"
                 class="is-small has-text-grey is-size-7 is-pulled-right"
                 @click="fetchList"
              >update now</a>
              <label class="label is-small">Last update</label>
              <div class="control">
                <input class="input is-small" v-model="selectedDoc.mdate" readonly/>
              </div>
            </div>
            <div class="field">
              <label class="label is-small">Tags</label>
              <div class="control">
                <tag-autocomplete-input :initialTag="selectedDocTags"
                                        :selectionType="'multiple'"
                                        @tagChanged="selectedDocTags = $event">
                </tag-autocomplete-input>
              </div>
              <p class="help">Separated by space.</p>
            </div>
            <div class="field">
              <label class="label is-small">Source</label>
              <div class="control">
                <input class="input is-small" v-model="selectedDoc.source"
                       :readonly="readonly"/>
              </div>
              <p class="help">Only 'self-managed' lists are fully editable. For Internet sourced lists, only metadata is
                editable.</p>
            </div>
            <div class="field">
              <label class="checkbox is-size-7">
                <input type="checkbox"
                       :readonly="readonly"
                       :disabled="readonly"
                       v-model="selectedDoc.active">
                Active
              </label>
            </div>
            <div class="field">
              <label class="label is-small">Notes</label>
              <div class="control">
                <textarea class="is-small textarea" v-model="selectedDoc.notes" rows="2"
                          :readonly="readonly"></textarea>
              </div>
            </div>
          </div>
          <div class="column is-8">
            <entries-relation-list :relation-list="selectedDoc.entriesRelation"
                                   :editable="editable">
            </entries-relation-list>
          </div>
        </div>
        <span class="is-family-monospace has-text-grey-lighter">{{ apiPath }}</span>
      </div>
    </div>
  </div>
</template>

<script>

import _ from 'lodash'

import TagAutocompleteInput from '@/components/TagAutocompleteInput'
import RequestsUtils from '@/assets/RequestsUtils'
import EntriesRelationList from '@/components/EntriesRelationList'

export default {
  name: 'ProfilingListEditor',

  components: {
    EntriesRelationList,
    TagAutocompleteInput
  },

  props: {
    selectedDoc: Object,
    apiPath: String
  },

  computed: {
    listTotalEntries() {
      return this.selectedDoc?.entries?.length
    },

    readonly() {
      return this.selectedDoc.source === 'reblaze-managed'
    },

    editable() {
      return this.selectedDoc.source === 'self-managed'
    },

    selectedDocTags: {
      get: function () {
        if (this.selectedDoc.tags)
          return this.selectedDoc.tags.join(' ')
        return ''
      },
      set: _.debounce(function (tags) {
        this.selectedDoc.tags = this.ld.map(tags.split(' '), (tag) => {
          return tag.trim()
        })
      }, 500)
    },

  },

  methods: {
    tryMatch(data, regex, type) {
      let matches, entries = []

      matches = regex.exec(data)
      while (matches) {

        let entry = [type, matches[1], null]

        if (matches.length > 2) {
          entry[2] = (matches.slice(-1)[0] || '').slice(0, 128)
        }

        entries.push(entry)
        matches = regex.exec(data)
      }

      return entries
    },

    fetchList() {
      const line_matching_ip = /^[^;]((((\d{1,3})\.){3}\d{1,3}(\/\d{1,2}))|([0-9a-f]+:+){1,8}([0-9a-f]+)?(\/\d{1,3})?)\s+([#;/].+)/gm,
          line_matching_asn = /(as\d{3,6})((\s+)?([#;/?].+))?/gmi,
          single_ip = /^((((\d{1,3})\.){3}\d{1,3}(\/\d{1,2}))|([0-9a-f]+:+){1,8}([0-9a-f]+)?(\/\d{1,3})?)$/,
          single_asn = /(as\d{3,6})/i

      // try every node / element of String type with the regex.
      let object_parser = (data, store) => {
        this.ld.each(data,
            (item) => {
              if (this.ld.isArray(item) || this.ld.isObject(item)) {
                object_parser(item, store)
              }
              if (this.ld.isString(item)) {
                if (single_ip.test(item)) {
                  store.push(['ip', item, null])
                } else if (single_asn.test(item)) {
                  store.push(['asn', item, null])
                }
              }
            })
      }

      let url = this.selectedDoc.source

      RequestsUtils.sendRequest('GET', `tools/fetch?url=${url}`).then(
          (response) => {

            let data = response.data,
                entries = []

            entries = this.tryMatch(data, line_matching_ip, 'ip')

            if (entries.length === 0) {
              entries = this.tryMatch(data, line_matching_asn, 'asn')
            }

            if (entries.length === 0) {
              try {
                object_parser(data, entries)
              } catch (e) {
                console.log(e)
              }
            }

            if (entries.length > 0) {
              this.selectedDoc.entries = entries
              this.selectedDoc.mdate = (new Date).toISOString()
            }

        })

    },
  },

}
</script>
