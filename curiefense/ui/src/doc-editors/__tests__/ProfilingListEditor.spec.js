import ProfilingListEditor from '@/doc-editors/ProfilingListEditor'
import {describe, test, expect} from '@jest/globals'
import {mount} from '@vue/test-utils'

describe('ProfilingListEditor.vue', () => {
    const docs = [{
        'id': 'xlbp148c',
        'name': 'API Discovery',
        'source': 'self-managed',
        'mdate': '2020-05-23T00:04:41',
        'notes': 'Tag API Requests',
        'active': true,
        'entries_relation': 'OR',
        'tags': ['api'],
        'entries': [['headers', ['content-type', '.*/(json|xml)'], 'content type'], ['headers', ['host', '.?ap[ip]\\.'], 'app or api in domain name'], ['method', '(POST|PUT|DELETE|PATCH)', 'Methods'], ['path', '/api/', 'api path'], ['uri', '/.+\\.json', 'URI JSON extention']]
    }, {
        'id': '07656fbe',
        'name': 'devop internal demo',
        'source': 'self-managed',
        'mdate': '2020-05-23T00:04:41',
        'notes': 'this is my own list',
        'active': false,
        'entries_relation': 'OR',
        'tags': ['internal', 'devops'],
        'entries': [['ip', '12.34.56.78/32', 'testers'], ['ip', '98.76.54.0/24', 'monitoring'], ['ip', '!5.4.3.2/32', 'old monitoring'], ['path', '/test/app/status', 'monitoring path']]
    }]

    test('should exist - STUB', () => {
        const wrapper = mount(ProfilingListEditor, {
            propsData: {
                selectedDoc: docs[0]
            }
        })
        expect(wrapper).toBeTruthy()
    })
})
