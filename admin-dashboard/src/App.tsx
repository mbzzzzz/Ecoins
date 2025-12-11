import { BrowserRouter, Routes, Route, NavLink } from 'react-router-dom'
import { LayoutDashboard, Gift, Building2, LogOut } from 'lucide-react'
import Dashboard from './pages/Dashboard'
import Rewards from './pages/Rewards'
import Brands from './pages/Brands'

function Sidebar() {
  return (
    <div className="sidebar">
      <h1>🌱 EcoAdmin</h1>
      <nav>
        <NavLink to="/" className={({ isActive }) => isActive ? 'active' : ''}>
          <LayoutDashboard size={20} /> Dashboard
        </NavLink>
        <NavLink to="/rewards" className={({ isActive }) => isActive ? 'active' : ''}>
          <Gift size={20} /> Rewards
        </NavLink>
        <NavLink to="/brands" className={({ isActive }) => isActive ? 'active' : ''}>
          <Building2 size={20} /> Brands
        </NavLink>
      </nav>
      <div style={{ marginTop: 'auto' }}>
        <a href="#" onClick={() => {/* Sign Out logic */ }}>
          <LogOut size={20} /> Sign Out
        </a>
      </div>
    </div>
  )
}

function App() {
  return (
    <BrowserRouter>
      <div className="layout">
        <Sidebar />
        <main className="main-content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/rewards" element={<Rewards />} />
            <Route path="/brands" element={<Brands />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  )
}

export default App
