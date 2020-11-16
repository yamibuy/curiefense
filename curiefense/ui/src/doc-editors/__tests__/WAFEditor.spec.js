import WAFEditor from '@/doc-editors/WAFEditor'
import {describe, test, expect} from '@jest/globals'
import {mount} from '@vue/test-utils'

describe('WAFEditor.vue', () => {
    const docs = [{
        'id': '__default__',
        'name': 'default waf',
        'ignore_alphanum': true,
        'max_header_length': 1024,
        'max_cookie_length': 1024,
        'max_arg_length': 1024,
        'max_headers_count': 42,
        'max_cookies_count': 42,
        'max_args_count': 512,
        'args': {'names': [], 'regex': []},
        'headers': {'names': [], 'regex': []},
        'cookies': {'names': [], 'regex': []}
    }]

    test('should exist - STUB', () => {
        const wrapper = mount(WAFEditor, {
            propsData: {
                selectedDoc: docs[0]
            }
        })
        expect(wrapper).toBeTruthy()
    })
})
