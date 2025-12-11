import { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'
import { Plus, Trash, Key, Copy, Check } from 'lucide-react'

export default function BrandRewards() {
    const [rewards, setRewards] = useState<any[]>([])
    const [loading, setLoading] = useState(true)
    const [brandId, setBrandId] = useState<string | null>(null)
    const [brandName, setBrandName] = useState('')
    const [apiKey, setApiKey] = useState('')
    const [copied, setCopied] = useState(false)

    // Form state
    const [title, setTitle] = useState('')
    const [description, setDescription] = useState('')
    const [cost, setCost] = useState(100)
    const [showForm, setShowForm] = useState(false)

    useEffect(() => {
        fetchBrandInfo()
    }, [])

    useEffect(() => {
        if (brandId) fetchRewards()
    }, [brandId])

    async function fetchBrandInfo() {
        const { data: { user } } = await supabase.auth.getUser()
        if (!user) return

        const { data: profile } = await supabase
            .from('profiles')
            .select('brand_id')
            .eq('id', user.id)
            .single()

        if (profile?.brand_id) {
            setBrandId(profile.brand_id)

            const { data: brand } = await supabase
                .from('brands')
                .select('name, api_key')
                .eq('id', profile.brand_id)
                .single()

            if (brand) {
                setBrandName(brand.name)
                setApiKey(brand.api_key)
            }
        }
        setLoading(false)
    }

    async function fetchRewards() {
        if (!brandId) return
        const { data } = await supabase
            .from('rewards')
            .select('*')
            .eq('brand_id', brandId)
            .order('created_at', { ascending: false })

        if (data) setRewards(data)
    }

    async function handleCreate(e: React.FormEvent) {
        e.preventDefault()
        if (!brandId) return

        const { error } = await supabase.from('rewards').insert([
            {
                title,
                description,
                cost_points: cost,
                brand_id: brandId,
                type: 'COUPON',
                is_active: true,
            }
        ])

        if (error) {
            alert('Error creating reward: ' + error.message)
        } else {
            setShowForm(false)
            setTitle('')
            setDescription('')
            fetchRewards()
        }
    }

    async function handleDelete(id: string) {
        if (!confirm('Are you sure you want to delete this coupon?')) return

        const { error } = await supabase.from('rewards').delete().eq('id', id)
        if (error) alert('Error: ' + error.message)
        else fetchRewards()
    }

    function copyApiKey() {
        navigator.clipboard.writeText(apiKey)
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
    }

    if (loading) return <div style={{ padding: '2rem' }}>Loading brand profile...</div>
    // If not loading and no brandId, show access denied
    if (!loading && !brandId) return <div style={{ padding: '2rem' }}>Access Denied. You are not linked to a brand.</div>

    return (
        <div>
            <div style={{ marginBottom: '2rem', background: 'white', padding: '1.5rem', borderRadius: '12px', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                <h2 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Key size={24} color="#10B981" />
                    Developer API
                </h2>
                <p style={{ color: '#6B7280', marginBottom: '1rem' }}>
                    Use this API Key to display your {brandName} Carbon Progress Bar on your website.
                </p>
                <div style={{ display: 'flex', gap: '8px', background: '#F3F4F6', padding: '0.75rem', borderRadius: '8px', alignItems: 'center' }}>
                    <code style={{ flex: 1, fontFamily: 'monospace', color: '#374151' }}>{apiKey || 'No API Key generated'}</code>
                    <button onClick={copyApiKey} style={{ border: 'none', background: 'none', cursor: 'pointer', color: '#6B7280' }}>
                        {copied ? <Check size={18} color="#10B981" /> : <Copy size={18} />}
                    </button>
                </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
                <div>
                    <h1 style={{ margin: 0, fontSize: '1.8rem' }}>{brandName} Coupons</h1>
                    <p style={{ color: '#6B7280', margin: '0.5rem 0 0 0' }}>Manage your active discount codes</p>
                </div>
                <button
                    className="btn-primary"
                    onClick={() => setShowForm(!showForm)}
                    style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                    <Plus size={20} /> New Coupon
                </button>
            </div>

            {showForm && (
                <div className="card" style={{ marginBottom: '2rem', border: '2px solid #10B981' }}>
                    <form onSubmit={handleCreate} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                        <input placeholder="Coupon Title (e.g. 20% Off)" value={title} onChange={e => setTitle(e.target.value)} required style={{ padding: '0.75rem', borderRadius: '6px', border: '1px solid #D1D5DB' }} />
                        <textarea placeholder="Description / Terms" value={description} onChange={e => setDescription(e.target.value)} required style={{ padding: '0.75rem', borderRadius: '6px', border: '1px solid #D1D5DB' }} />
                        <div style={{ display: 'flex', gap: '1rem' }}>
                            <input type="number" placeholder="Cost (EcoPoints)" value={cost} onChange={e => setCost(Number(e.target.value))} required style={{ padding: '0.75rem', borderRadius: '6px', border: '1px solid #D1D5DB' }} />
                            <button type="submit" className="btn-primary">Create Coupon</button>
                        </div>
                    </form>
                </div>
            )}

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1.5rem' }}>
                {rewards.map(reward => (
                    <div key={reward.id} className="card" style={{ position: 'relative' }}>
                        <button
                            onClick={() => handleDelete(reward.id)}
                            style={{ position: 'absolute', top: '1rem', right: '1rem', border: 'none', background: 'none', color: '#EF4444', cursor: 'pointer' }}
                        >
                            <Trash size={18} />
                        </button>
                        <h3 style={{ marginTop: 0, paddingRight: '2rem' }}>{reward.title}</h3>
                        <p style={{ color: '#6B7280', fontSize: '0.9rem' }}>{reward.description}</p>
                        <div style={{ marginTop: '1rem', fontWeight: 'bold', color: '#10B981' }}>
                            {reward.cost_points} Points
                        </div>
                    </div>
                ))}
            </div>
        </div>
    )
}
