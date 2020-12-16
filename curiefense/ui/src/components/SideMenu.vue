<template>

  <aside class="menu mt-3">
    <div v-for="(sectionItems, sectionTitle) in menuItems" :key="sectionTitle" class="menu-item">
      <p class="menu-label">
        {{ sectionTitle }}
      </p>
      <ul class="menu-list">
        <li v-for="(menuItemDetails, menuItemKey) in sectionItems" :key="menuItemKey" class="section-item">
          <router-link :data-curie="menuItemKey"
                       :to="menuItemKey"
                       :class="{ 'is-active': currentRoutePath === menuItemKey }">
            {{ menuItemDetails.title }}
          </router-link>
        </li>
      </ul>
    </div>
  </aside>

</template>

<script>

export default {

  name: 'SideMenu',

  data() {
    return {
      selectedMenuItem: null,
      menuItems: {
        Settings: {
          '/config': {'title': 'Policies & Rules'},
          '/db': {'title': 'System DB'},
          '/publish': {'title': 'Publish Changes'},
        },
        Analytics: {
          '/accesslog': {'title': 'Access Log'}
        },
        Git: {
          '/versioncontrol': {'title': 'Version Control'}
        },
      }
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
<style scoped>
.menu-label {
  color: #8F99A3;
  font-weight: 700;
}

.menu-list a {
  color: #0F1D38;
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
