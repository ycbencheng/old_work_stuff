import React from 'react'
import 'select2'

class storeDropdown extends React.Component {
  handleChange(event) {
    let new_url = window.location.pathname === '/' ? `/stores/${event.target.value}/monthly_activities` : window.location.href.replace(/stores\/\d+\//, `stores/${event.target.value}/`)
    window.location.href = new_url
  }

  componentDidMount() {
    let select = $('#store')
    select.select2()
    select.on('change', this.handleChange)
  }

  render() {
    return (
      <select id='store' value={this.props.selected} readOnly className='form-control'>
        {
          this.props.stores.map(store => {
            return(<option key={store.id} value={store.id}>{store.name}</option>);
          })
        }
      </select>
    )
  }
}
export default storeDropdown;
