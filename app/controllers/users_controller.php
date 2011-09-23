<?php

class UsersController extends AppController {

  var $name = 'Users';

  function beforeFilter() {
    $this->disableCache();
    $this->Auth->allowedActions = array('login', 'logout', 'auth');

    $this->Cookie->name = 'TODOS';
    $this->Cookie->time = 3600; // 1 hour

    parent::beforeFilter();
  }

  function login() {
    $user = $this->Auth->user();
    if ($user) {
      $merged = array_merge($this->data['User'], array('id' => $this->Auth->user('id'), 'username' => $this->Auth->user('username'), 'name' => $this->Auth->user('name'), 'password' => '', 'sessionid' => $this->Session->id(), 'flash' => '<strong style="color:green">You\'re successfully logged in as ' . $this->Auth->user('name') . '</strong>'));
      $json = $merged;
      $this->set(compact('json'));
      $this->render(SIMPLE_JSON);
    } elseif (isset($this->data)) {
      $merged = array_merge($this->data['User'], array('id' => '', 'username' => '', 'name' => '', 'password' => '', 'sessionid' => '', 'flash' => '<strong style="color:red">Login failed</strong>'));
      $json = $merged;
      $this->set(compact('json'));
      $this->header("HTTP/1.1 403 Forbidden");
      $this->render(SIMPLE_JSON);
    }
  }

  function logout() {
    if ($this->params['isAjax']) {
      $this->Auth->logout();
    }
    $merged = array_merge($this->data['User'], array('id' => '', 'username' => '', 'name' => '', 'password' => '', 'sessionid' => '', 'flash' => '<strong>You\'re logged out successfully</strong>'));
    $json = $merged;
    $this->set(compact('json'));
    $this->render(SIMPLE_JSON);
  }

  function auth() {
    if ($this->params['isAjax'] && $this->Auth->user()) {
      $user = $this->Auth->user();
      $merged = array_merge($this->data['User'], $user['User']);
      $json = $merged;
    } elseif (isset($this->data)) {
      $json = $this->data['User'];
    }
    $this->set(compact('json'));
    $this->render(SIMPLE_JSON);
  }

  function add() {
    $this->log($data, LOG_DEBUG);
  }
}

?>