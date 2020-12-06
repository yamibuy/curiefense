import SerializedInput from '@/components/SerializedInput'
import {describe, test, expect} from '@jest/globals'
import {mount} from '@vue/test-utils'

describe('SerializedInput.vue', () => {
    test('should exist - STUB', () => {
        const wrapper = mount(SerializedInput)
        expect(wrapper).toBeTruthy()
    })
})
