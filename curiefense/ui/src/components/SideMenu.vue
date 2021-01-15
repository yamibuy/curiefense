<template>

  <aside class="menu mt-3">
    <div v-for="(sectionItems, sectionTitle) in menuItems" :key="sectionTitle" class="menu-item">
      <p class="menu-label">
        {{ sectionTitle }}
      </p>
      <ul class="menu-list">
        <li v-for="(menuItemDetails, menuItemKey) in sectionItems" :key="menuItemKey" class="section-item">
          <router-link :data-curie="menuItemKey" v-if="! menuItemDetails.external"
                       :to="menuItemKey"
                       :class="{ 'is-active': currentRoutePath.includes(menuItemKey) }">
            {{ menuItemDetails.title }}
          </router-link>
          <a v-if="menuItemDetails.external"
              :data-curie="menuItemKey"
              :href="menuItemKey"
              target="_blank"
          >
            {{ menuItemDetails.title }}
          </a>
          <ul v-if="menuItemDetails.items"
              class="my-0">
            <li v-for="(menuSubItemDetails, menuSubItemKey) in menuItemDetails.items" :key="menuSubItemKey">
              <router-link :data-curie="menuSubItemKey"
                           :to="menuSubItemKey"
                           :class="{ 'is-active': currentRoutePath.includes(menuSubItemKey) }">
                {{ menuSubItemDetails.title }}
              </router-link>
            </li>
          </ul>
        </li>
      </ul>
    </div>
  </aside>

</template>

<script>
export default {
  name: 'SideMenu',
  data() {
    const kibana_href = "//" + location.origin.replace(":30080", ":5601/app/discover")
    let _menuItems = {
        Settings: {
          '/config': {
            'title': 'Policies & Rules',
            'items': {
              '/search': {'title': 'Search'}
            }
          },
          '/db': {'title': 'System DB'},
          '/publish': {'title': 'Publish Changes'},
        },
        Analytics: {},
        Git: {
          '/versioncontrol': {'title': 'Version Control'}
        },
      }

    _menuItems.Analytics[kibana_href] = {'title': 'Access Log', "external": true}

    return {
      selectedMenuItem: null,
      menuItems: _menuItems
    }
  },
  computed: {
    currentRoutePath() {
      return this.$route.path
    }
  },
  methods: {},
}
</script>
<style scoped lang="scss">
.menu-item {
  margin-top: 1.5rem;
  &:first-child {
    margin-top: 0
  }
}
.menu-label {
  color: #8f99a3;
  font-weight: 700;
  margin-bottom: 0;
}
.menu-list a {
  color: #0f1d38;
  font-size: 14px;
  font-weight: 700;
}
.menu-list a:hover {
  background-color: transparent;
  color: #276cda;
}
.menu-list a.is-active {
  background-color: transparent;
  color: #276cda;
  font-weight: 700;
}
</style>
