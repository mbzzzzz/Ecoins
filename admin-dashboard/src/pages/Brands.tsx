import { useEffect, useState } from 'react'
import { supabase } from '../supabaseClient'
import { ExternalLink } from 'lucide-react'

export default function Brands() {
    const [brands, setBrands] = useState<any[]>([])
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        async function fetchBrands() {
            const { data } = await supabase.from('brands').select('*')
            if (data) setBrands(data)
            setLoading(false)
        }
        fetchBrands()
    }, [])

    return (
        <div>
            <h2>Registered Brands</h2>
            <p style={{ color: '#6B7280', marginBottom: '2rem' }}>Manage brand integrations and API access.</p>

            {loading ? <p>Loading...</p> : (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '1.5rem' }}>
                    {brands.map(brand => (
                        <div key={brand.id} className="card">
                            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '1rem' }}>
                                <div style={{ width: '48px', height: '48px', background: '#F3F4F6', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                    {brand.logo_url ? <img src={brand.logo_url} width={32} alt="" /> : <span style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#9CA3AF' }}>{brand.name[0]}</span>}
                                </div>
                                <div>
                                    <h3 style={{ margin: 0 }}>{brand.name}</h3>
                                    <a href={brand.webhook_url} target="_blank" rel="noreferrer" style={{ fontSize: '0.875rem', color: '#10B981', textDecoration: 'none', display: 'flex', alignItems: 'center', gap: '4px' }}>
                                        Webhook Configured <ExternalLink size={12} />
                                    </a>
                                </div>
                            </div>
                            <div style={{ borderTop: '1px solid #E5E7EB', paddingTop: '1rem', marginTop: '1rem' }}>
                                <p style={{ fontSize: '0.75rem', color: '#6B7280', margin: 0 }}>
                                    ID: <span style={{ fontFamily: 'monospace' }}>{brand.id}</span>
                                </p>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    )
}
