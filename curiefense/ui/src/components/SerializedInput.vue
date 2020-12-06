<template>
  <div>
    <input required
           type="text"
           class="serialized-input input is-small"
           v-model="formattedValue"
           @blur="updateValue($event.target.value)"
           :placeholder="placeholder"/>
  </div>
</template>

<script>

export default {
  name: 'SerializedInput',
  props: {
    value: Object,
    placeholder: String,
    getFunction: Function,
    setFunction: Function
  },
  data() {
    return {
      formattedValue: ''
    }
  },
  watch: {
    value: function () {
      this.formatValue()
    }
  },
  mounted: function () {
    this.formatValue()
  },
  methods: {
    updateValue: function (newValue) {
      if (typeof this.setFunction === 'function') {
        const result = this.setFunction(newValue)
        this.$emit('blur', result)
      }
    },
    formatValue: function () {
      if (typeof this.getFunction === 'function') {
        this.formattedValue = this.getFunction(this.value)
      }
    }
  }
}
</script>
