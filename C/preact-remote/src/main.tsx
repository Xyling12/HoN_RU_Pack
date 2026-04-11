console.log('[HoN_RU_REMOTE] main loaded');
import './styles/global.css'
import { render } from 'preact'
import { App } from './app.tsx'

render(<App />, document.getElementById('app')!)
