/**
 *
 * @author fuyg
 * @date  CREATE_DATE
 */

import Vue from 'vue'
// import { mapState, mapGetters, mapActions } from 'vuex'

export default Vue.extend({
  name: 'ComponentName',

  // components: {},

  // props: {},

  // mixins: [],

  data() {
    return {
      // TODO
    }
  },

  computed: {
    withSetter: {
      get() {
        // TODO
      },
      set(/* value */) {
        // TODO
      },
    },

    // TODO
  },

  watch: {
    // TODO
  },

  methods: {
    async fetchData() {
      // TODO
    },
    // TODO
  },

  filters: {
    // TODO
  },

  /**
   * life cycle
   */
  created() {
    this.fetchData()
  },
  // mounted() {},
  // beforeDestroy() {},
})
