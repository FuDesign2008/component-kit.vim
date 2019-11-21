/**
 *
 * @author fuyg
 * @date  CREATE_DATE
 */
import Vue from 'vue'
import Component /*, { mixins } */ from 'vue-class-component'
// import { Prop, Ref, Watch } from 'vue-property-decorator'
// import { Action, Getter, namespace, State } from 'vuex-class'
// const storeModule = namespace('store-module-name')

/* tslint:disable:member-ordering */

@Component({
  // name: '',
  // el: '#id',
  // components: {
  // TODO
  // },
  // filters and directives can be extracted to other files
  // filters: {
  // TODO
  // },
  // directives: {
  // TODO
  // },
})
class ComponentName extends Vue /*mixins(ComponentNameMixin) */ {
  /**************************************************************************
   * props
   **************************************************************************/

  // @Prop({
  // type: String,
  // required: true
  // })
  // private readonly requiredProp!: string

  /**************************************************************************
   * vuex map state / getters / actions
   **************************************************************************/

  // @State
  // private readonly foo!: string

  // @Getter
  // private readonly bar!: string

  // @Action
  // private baz!: () => Promise<void>

  // @storeModule.State('name')
  // private readonly aliasName!: string | null

  /**************************************************************************
   * data
   **************************************************************************/

  // private dataName: number = 0

  /**************************************************************************
   * computed
   **************************************************************************/

  // private get computedName(): string {
  // TODO
  // return ''
  // }

  /**************************************************************************
   * $ref
   **************************************************************************/
  // @Ref()
  // private readonly anotherComponent!: AnotherComponent

  // @Ref('button-name')
  // private readonly button!: HTMLButtonElement

  /**************************************************************************
   * watch
   **************************************************************************/

  // @Watch('dataName')
  // dataNameOnChange(newValue: number, oldValue: number): void {
  // TODO
  // }

  /**************************************************************************
   * methods
   **************************************************************************/

  private async fetchData(): Promise<void> {
    // TODO
  }

  /**************************************************************************
   * life cycle
   **************************************************************************/

  // beforeCreate(): void {}
  created(): void {
    this.fetchData()
  }
  // beforeMount(): void {}
  // mounted(): void {}
  // beforeUpate(): void {}
  // updated(): void {}
  // beforeDestroy(): void {}
  // destroyed(): void {}
}

export default ComponentName
