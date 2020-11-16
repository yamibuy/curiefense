import RateLimitsEditor from '@/doc-editors/RateLimitsEditor'
import {describe, test, expect} from '@jest/globals'
import {shallowMount} from '@vue/test-utils'

describe('RateLimitsEditor.vue', () => {
    const docs = [{
        'id': 'f971e92459e2',
        'name': 'Rate Limit Example Rule 5/60',
        'description': '5 requests per minute',
        'ttl': '60',
        'limit': '5',
        'action': {'type': 'default', 'params': {'action': {'type': 'default', 'params': {}}}},
        'include': {'headers': {}, 'cookies': {}, 'args': {}, 'attrs': {}},
        'exclude': {'headers': {}, 'cookies': {}, 'args': {}, 'attrs': {}},
        'key': [{'attrs': 'ip'}],
        'pairwith': {'self': 'self'}
    }]

    test('should exist - STUB', () => {
        const wrapper = shallowMount(RateLimitsEditor, {
            propsData: {
                selectedDoc: docs[0]
            }
        })
        expect(wrapper).toBeTruthy()
    })
})
