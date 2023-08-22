import React from 'react';
import logo from './logo.svg';
import './App.css';
import { BrowserRouter, Link } from 'react-router-dom'
import { Button } from 'antd';
const { name} = require('../package.json')
const isPro = process.env.NODE_ENV === 'production'

function App() {
  // @ts-ignore
  const basename = window.__POWERED_BY_QIANKUN__ ? `/${name}` : isPro ? `/child/${name}` : '/'

  return (
    <BrowserRouter basename={basename}>
      <div className="App">
       {name}
      </div>
      <Button type="primary">Primary</Button>
      <Button>Default</Button>
      <Button type="dashed">Dashed</Button>
      <Button type="link">Link</Button>
    </BrowserRouter>
  );
}

export default App;
