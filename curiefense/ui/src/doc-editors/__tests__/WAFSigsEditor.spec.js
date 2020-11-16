import WAFSigsEditor from '@/doc-editors/WAFSigsEditor'
import {describe, test, expect} from '@jest/globals'
import {mount} from '@vue/test-utils'

describe('WAFSigsEditor.vue', () => {
    const docs = [{
        'id': '100000',
        'name': '100000',
        'msg': 'SQLi Attempt (Conditional Operator Detected)',
        'operand': '\\s(and|or)\\s+\\d+\\s+.*between\\s.*\\d+\\s+and\\s+\\d+.*',
        'severity': 5,
        'certainity': 5,
        'category': 'sqli',
        'subcategory': 'statement injection'
    }, {
        'id': '100001',
        'name': '100001',
        'msg': 'SQLi Attempt (Conditional Operator Detected)',
        'operand': '\\s(and|or)\\s+["\']\\w+["\']\\s+.*between\\s.*["\']\\w+["\']\\s+and\\s+["\']\\w+.*',
        'severity': 5,
        'certainity': 5,
        'category': 'sqli',
        'subcategory': 'statement injection'
    }]

    test('should exist - STUB', () => {
        const wrapper = mount(WAFSigsEditor, {
            propsData: {
                selectedDoc: docs[0]
            }
        })
        expect(wrapper).toBeTruthy()
    })
})
