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
      const result = this.setFunction(newValue)
      this.$emit('blur', result)
    },
    formatValue: function () {
      this.formattedValue = this.getFunction(this.value)
    }
  }
}
</script>
