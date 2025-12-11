import { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'
import { Plus, Trash2, Edit2 } from 'lucide-react'

interface Reward {
    id: string
    title: string
    cost_points: number
    active: boolean
    brands: { name: string } | null
}

export default function Rewards() {
    const [rewards, setRewards] = useState<Reward[]>([])
    const [loading, setLoading] = useState(true)
    const [showModal, setShowModal] = useState(false)

    // New Reward Form State
    const [formData, setFormData] = useState({
        title: '',
        cost_points: 100,
        brand_id: '', // Would need to select from brands
        active: true
    })
    const [brands, setBrands] = useState<any[]>([])

    useEffect(() => {
        fetchRewards()
        fetchBrands()
    }, [])

    async function fetchRewards() {
        const { data, error } = await supabase
            .from('rewards')
            .select('*, brands(name)')
            .order('created_at', { ascending: false })

        if (data) setRewards(data)
        setLoading(false)
    }

    async function fetchBrands() {
        const { data } = await supabase.from('brands').select('id, name')
        if (data) setBrands(data)
    }

    async function handleDelete(id: string) {
        if (!confirm('Are you sure you want to delete this reward?')) return
        await supabase.from('rewards').delete().eq('id', id)
        fetchRewards()
    }

    async function handleCreate(e: React.FormEvent) {
        e.preventDefault()
        if (!formData.brand_id) return alert('Please select a brand')

        const { error } = await supabase.from('rewards').insert([{
            title: formData.title,
            cost_points: formData.cost_points,
            brand_id: formData.brand_id,
            active: formData.active
        }])

        if (error) alert(error.message)
        else {
            setShowModal(false)
            fetchRewards()
            setFormData({ title: '', cost_points: 100, brand_id: '', active: true })
        }
    }

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <h2>Rewards Management</h2>
                <button className="btn" onClick={() => setShowModal(true)}>
                    <Plus size={16} style={{ marginBottom: '-2px' }} /> Add Reward
                </button>
            </div>

            {loading ? <p>Loading...</p> : (
                <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
                    <table cellPadding={0} cellSpacing={0}>
                        <thead style={{ background: '#F9FAFB' }}>
                            <tr>
                                <th>Title</th>
                                <th>Brand</th>
                                <th>Cost (Pts)</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {rewards.map(reward => (
                                <tr key={reward.id}>
                                    <td style={{ fontWeight: 500 }}>{reward.title}</td>
                                    <td>{reward.brands?.name || 'Unknown'}</td>
                                    <td>{reward.cost_points}</td>
                                    <td>
                                        <span style={{
                                            background: reward.active ? '#D1FAE5' : '#F3F4F6',
                                            color: reward.active ? '#065F46' : '#374151',
                                            padding: '2px 8px', borderRadius: '12px', fontSize: '0.75rem', fontWeight: 600
                                        }}>
                                            {reward.active ? 'Active' : 'Inactive'}
                                        </span>
                                    </td>
                                    <td>
                                        <button onClick={() => handleDelete(reward.id)} style={{ background: 'none', border: 'none', color: '#EF4444', cursor: 'pointer' }}>
                                            <Trash2 size={18} />
                                        </button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            )}

            {showModal && (
                <div style={{
                    position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
                    background: 'rgba(0,0,0,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center'
                }}>
                    <div className="card" style={{ width: '400px', margin: 0 }}>
                        <h3>Create New Reward</h3>
                        <form onSubmit={handleCreate} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                            <div>
                                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem' }}>Title</label>
                                <input
                                    type="text" required
                                    value={formData.title}
                                    onChange={e => setFormData({ ...formData, title: e.target.value })}
                                    style={{ width: '100%', padding: '0.5rem', borderRadius: '0.375rem', border: '1px solid #D1D5DB' }}
                                />
                            </div>

                            <div>
                                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem' }}>Brand</label>
                                <select
                                    required
                                    value={formData.brand_id}
                                    onChange={e => setFormData({ ...formData, brand_id: e.target.value })}
                                    style={{ width: '100%', padding: '0.5rem', borderRadius: '0.375rem', border: '1px solid #D1D5DB' }}
                                >
                                    <option value="">Select Brand</option>
                                    {brands.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
                                </select>
                            </div>

                            <div>
                                <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem' }}>Points Cost</label>
                                <input
                                    type="number" required
                                    value={formData.cost_points}
                                    onChange={e => setFormData({ ...formData, cost_points: parseInt(e.target.value) })}
                                    style={{ width: '100%', padding: '0.5rem', borderRadius: '0.375rem', border: '1px solid #D1D5DB' }}
                                />
                            </div>

                            <div style={{ display: 'flex', gap: '1rem', marginTop: '1rem' }}>
                                <button type="button" className="btn" style={{ background: '#E5E7EB', color: 'black' }} onClick={() => setShowModal(false)}>Cancel</button>
                                <button type="submit" className="btn">Create</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    )
}
