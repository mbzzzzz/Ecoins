import { BrowserRouter, Routes, Route, NavLink, Navigate } from 'react-router-dom'
import { LayoutDashboard, Gift, Building2, LogOut } from 'lucide-react'
import { useEffect, useState } from 'react'
import { supabase } from './supabaseClient'
import type { Session } from '@supabase/supabase-js'

import Dashboard from './pages/Dashboard'
import Rewards from './pages/Rewards'
import Brands from './pages/Brands'
import Login from './pages/Login'
import BrandSignup from './pages/BrandSignup'
import BrandRewards from './pages/BrandRewards'

function Sidebar() {
  const [role, setRole] = useState<'admin' | 'brand' | 'loading'>('loading')

  useEffect(() => {
    checkRole()
  }, [])

  async function checkRole() {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data: profile } = await supabase
      .from('profiles')
      .select('brand_id')
      .eq('id', user.id)
      .single()

    if (profile?.brand_id) {
      setRole('brand')
    } else {
      setRole('admin')
    }
  }

  const handleSignOut = async () => {
    await supabase.auth.signOut()
  }

  if (role === 'loading') return null

  return (
    <div className="sidebar">
      <div className="brand">
        <img src="/logo.png" alt="EcoAdmin" className="brand-logo" />
        <h1>{role === 'brand' ? 'BrandPortal' : 'EcoAdmin'}</h1>
      </div>
      <nav>
        {role === 'admin' && (
          <>
            <NavLink to="/" className={({ isActive }) => isActive ? 'active' : ''}>
              <LayoutDashboard size={20} /> Dashboard
            </NavLink>
            <NavLink to="/rewards" className={({ isActive }) => isActive ? 'active' : ''}>
              <Gift size={20} /> Rewards
            </NavLink>
            <NavLink to="/brands" className={({ isActive }) => isActive ? 'active' : ''}>
              <Building2 size={20} /> Brands
            </NavLink>
          </>
        )}
        {role === 'brand' && (
          <NavLink to="/my-rewards" className={({ isActive }) => isActive ? 'active' : ''}>
            <Gift size={20} /> My Rewards
          </NavLink>
        )}
      </nav>
      <div style={{ marginTop: 'auto' }}>
        <a href="#" onClick={handleSignOut}>
          <LogOut size={20} /> Sign Out
        </a>
      </div>
    </div>
  )
}

function App() {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setLoading(false)
    })

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })

    return () => subscription.unsubscribe()
  }, [])

  if (loading) return null

  return (
    <BrowserRouter>
      <Routes>
        {/* Public Routes */}
        <Route path="/login" element={!session ? <Login /> : <Navigate to="/" />} />
        <Route path="/brand-signup" element={!session ? <BrandSignup /> : <Navigate to="/" />} />

        {/* Protected Routes */}
        <Route
          path="*"
          element={
            session ? (
              <div className="layout">
                <Sidebar />
                <main className="main-content">
                  <Routes>
                    <Route path="/" element={<Dashboard />} />
                    <Route path="/rewards" element={<Rewards />} />
                    <Route path="/brands" element={<Brands />} />
                    <Route path="/my-rewards" element={<BrandRewards />} />
                  </Routes>
                </main>
              </div>
            ) : (
              <Navigate to="/login" />
            )
          }
        />
      </Routes>
    </BrowserRouter>
  )
}

export default App
