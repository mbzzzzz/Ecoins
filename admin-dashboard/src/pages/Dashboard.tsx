import { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'

export default function Dashboard() {
    const [stats, setStats] = useState({ users: 0, brands: 0, carbon: 0 })
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        async function fetchStats() {
            // 1. Count Users
            const { count: userCount } = await supabase.from('profiles').select('*', { count: 'exact', head: true })

            // 2. Count Brands
            const { count: brandCount } = await supabase.from('brands').select('*', { count: 'exact', head: true })

            // 3. Sum Carbon Saved (Client-side sum for MVP, easier than creating view rn)
            const { data: profiles } = await supabase.from('profiles').select('carbon_saved_kg')
            const totalCarbon = profiles?.reduce((acc, curr) => acc + (curr.carbon_saved_kg || 0), 0) || 0

            setStats({
                users: userCount || 0,
                brands: brandCount || 0,
                carbon: totalCarbon
            })
            setLoading(false)
        }

        fetchStats()
    }, [])

    if (loading) return <div>Loading analytics...</div>

    // Mock data for chart (Real data requires aggregation query)
    const chartData = [
        { name: 'Mon', active: 40 },
        { name: 'Tue', active: 30 },
        { name: 'Wed', active: 20 },
        { name: 'Thu', active: 55 },
        { name: 'Fri', active: 70 },
        { name: 'Sat', active: 90 },
        { name: 'Sun', active: 65 },
    ]

    return (
        <div>
            <h2>Dashboard Overview</h2>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '1.5rem', marginBottom: '2rem' }}>
                <div className="card">
                    <h3 style={{ margin: 0, color: '#6B7280' }}>Total Users</h3>
                    <p style={{ fontSize: '2rem', fontWeight: 'bold', margin: '0.5rem 0 0' }}>{stats.users}</p>
                </div>
                <div className="card">
                    <h3 style={{ margin: 0, color: '#6B7280' }}>CO₂ Saved (kg)</h3>
                    <p style={{ fontSize: '2rem', fontWeight: 'bold', margin: '0.5rem 0 0', color: '#10B981' }}>
                        {stats.carbon.toFixed(1)}
                    </p>
                </div>
                <div className="card">
                    <h3 style={{ margin: 0, color: '#6B7280' }}>Active Brands</h3>
                    <p style={{ fontSize: '2rem', fontWeight: 'bold', margin: '0.5rem 0 0' }}>{stats.brands}</p>
                </div>
            </div>

            <div className="card" style={{ height: '400px' }}>
                <h3>Weekly Activity</h3>
                <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={chartData}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="name" />
                        <YAxis />
                        <Tooltip />
                        <Line type="monotone" dataKey="active" stroke="#10B981" strokeWidth={2} />
                    </LineChart>
                </ResponsiveContainer>
            </div>
        </div>
    )
}
