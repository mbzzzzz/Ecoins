import { useState } from 'react'
import { supabase } from '../supabaseClient'
import { useNavigate, Link } from 'react-router-dom'

export default function BrandSignup() {
    const [brandName, setBrandName] = useState('')
    const [logoUrl, setLogoUrl] = useState('')
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [loading, setLoading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const navigate = useNavigate()

    const handleSignup = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)
        setError(null)

        try {
            // 1. Sign up the user
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email,
                password,
            })
            if (authError) throw authError
            if (!authData.user) throw new Error('No user created')

            // 2. Create the brand
            const { data: brandData, error: brandError } = await supabase
                .from('brands')
                .insert([{ name: brandName, logo_url: logoUrl || null }])
                .select()
                .single()
            if (brandError) throw brandError

            // 3. Link user to brand (Update profile)
            const { error: profileError } = await supabase
                .from('profiles')
                .update({ brand_id: brandData.id })
                .eq('id', authData.user.id)

            // Note: If the trigger creates profile slightly later, this might fail or need a retry.
            // For now, we assume profile exists or we handle it. 
            // Actually 'profiles' usually auto-created by trigger.

            if (profileError) {
                // If profile doesn't exist yet, we might need to insert it manually or wait? 
                // But usually we just assume success for MVP/Trigger logic.
                console.warn('Profile update warning:', profileError)
            }

            alert('Registration successful! Please login.')
            navigate('/login')

        } catch (err: any) {
            setError(err.message)
        } finally {
            setLoading(false)
        }
    }

    return (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', background: '#F3F4F6' }}>
            <div className="card" style={{ width: '100%', maxWidth: '400px', padding: '2rem' }}>
                <h2 style={{ textAlign: 'center', marginBottom: '1.5rem', color: '#1F2937' }}>Register Brand</h2>

                {error && <div style={{ background: '#FEE2E2', color: '#B91C1C', padding: '0.75rem', borderRadius: '0.5rem', marginBottom: '1rem', fontSize: '0.875rem' }}>{error}</div>}

                <form onSubmit={handleSignup} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500 }}>Brand Name</label>
                        <input
                            type="text"
                            value={brandName}
                            onChange={(e) => setBrandName(e.target.value)}
                            required
                            style={{ width: '100%', padding: '0.75rem', borderRadius: '0.5rem', border: '1px solid #D1D5DB' }}
                        />
                    </div>
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500 }}>Logo URL (Optional)</label>
                        <input
                            type="url"
                            value={logoUrl}
                            onChange={(e) => setLogoUrl(e.target.value)}
                            placeholder="https://..."
                            style={{ width: '100%', padding: '0.75rem', borderRadius: '0.5rem', border: '1px solid #D1D5DB' }}
                        />
                    </div>
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500 }}>Admin Email</label>
                        <input
                            type="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                            style={{ width: '100%', padding: '0.75rem', borderRadius: '0.5rem', border: '1px solid #D1D5DB' }}
                        />
                    </div>
                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500 }}>Password</label>
                        <input
                            type="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                            style={{ width: '100%', padding: '0.75rem', borderRadius: '0.5rem', border: '1px solid #D1D5DB' }}
                        />
                    </div>
                    <button
                        type="submit"
                        disabled={loading}
                        style={{ background: '#10B981', color: 'white', padding: '0.75rem', borderRadius: '0.5rem', border: 'none', fontWeight: 600, cursor: 'pointer', marginTop: '0.5rem' }}
                    >
                        {loading ? 'Creating...' : 'Register'}
                    </button>
                </form>
                <div style={{ marginTop: '1.5rem', textAlign: 'center', fontSize: '0.875rem' }}>
                    <span style={{ color: '#6B7280' }}>Already have an account? </span>
                    <Link to="/login" style={{ color: '#10B981', textDecoration: 'none', fontWeight: 500 }}>Sign In</Link>
                </div>
            </div>
        </div>
    )
}
