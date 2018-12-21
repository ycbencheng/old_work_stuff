import FlashMessage from '../FlashMessage';
import React from 'react';
import ReactDOM from 'react-dom';
import dt from 'datatables.net';

class UsersController {
  index(){
    let table = $('table').DataTable({
      dom: 't<"bottom"ilp>'
    });
    $('.add-to-existing').click((event) => {
      let link = $(event.target).parent('a')
      let name = link.data('workerName');
      let worker_id = link.data('workerId');
      let store = link.data('store');
      $('#worker').val(name)
      $('.save').click((e) => {
        let user = $('#user').val()
        $.ajax({
          type: 'POST',
          beforeSend: function(xhr) {xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))},
          url: `/storeships/${store}/users/${user}/add_worker.json?worker_id=${worker_id}`
        }).then((data) => {
          $('#worker_to_user_modal').modal('hide');
          table.row($(event.target).parents('tr')).remove().draw();
          ReactDOM.render(<FlashMessage klass='notice' message={data.message} />, $('.flash-container')[0]);
        }).catch((error) => {
          ReactDOM.render(<FlashMessage klass='warning' message={error.message} />, $('.flash-container')[0]);
        });
      });
    });
  }
}
export default UsersController;
