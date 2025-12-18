import { useState, useCallback } from 'react'
import { supabase } from '../supabaseClient'
import { useNavigate, Link } from 'react-router-dom'
import { Upload, X, Loader2 } from 'lucide-react'

export default function BrandSignup() {
    const [brandName, setBrandName] = useState('')
    const [logoFile, setLogoFile] = useState<File | null>(null)
    const [logoPreview, setLogoPreview] = useState<string | null>(null)
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [loading, setLoading] = useState(false)
    const [uploading, setUploading] = useState(false)
    const [error, setError] = useState<string | null>(null)
    const [isDragging, setIsDragging] = useState(false)
    const navigate = useNavigate()

    // Drag and Drop Handlers
    const handleDrag = useCallback((e: React.DragEvent) => {
        e.preventDefault()
        e.stopPropagation()
        if (e.type === 'dragenter' || e.type === 'dragover') {
            setIsDragging(true)
        } else if (e.type === 'dragleave') {
            setIsDragging(false)
        }
    }, [])

    const handleDrop = useCallback((e: React.DragEvent) => {
        e.preventDefault()
        e.stopPropagation()
        setIsDragging(false)
        if (e.dataTransfer.files && e.dataTransfer.files[0]) {
            const file = e.dataTransfer.files[0]
            if (file.type.startsWith('image/')) {
                setLogoFile(file)
                setLogoPreview(URL.createObjectURL(file))
            } else {
                alert('Please upload an image file')
            }
        }
    }, [])

    const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            const file = e.target.files[0]
            if (file.type.startsWith('image/')) {
                setLogoFile(file)
                setLogoPreview(URL.createObjectURL(file))
            }
        }
    }

    const handleSignup = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)
        setError(null)
        setUploading(true)

        try {
            let publicLogoUrl = null

            // 1. Upload Image if present
            if (logoFile) {
                const fileExt = logoFile.name.split('.').pop()
                const fileName = `${Date.now()}.${fileExt}`
                const filePath = `${fileName}`

                const { error: uploadError } = await supabase.storage
                    .from('brand-logos')
                    .upload(filePath, logoFile)

                if (uploadError) throw uploadError

                const { data: { publicUrl } } = supabase.storage
                    .from('brand-logos')
                    .getPublicUrl(filePath)

                publicLogoUrl = publicUrl
            }

            // 2. Sign up user
            const { data: authData, error: authError } = await supabase.auth.signUp({
                email,
                password,
            })

            if (authError) throw authError
            if (!authData.user) throw new Error('No user created')

            // 3. Create Brand (associate with this auth user as owner)
            const brandPayload = {
                owner_user_id: authData.user.id,
                name: brandName,
                logo_url: publicLogoUrl,
                website_url: null as string | null,
            }
            console.log('Creating brand with payload', brandPayload)

            const { data: brandData, error: brandError } = await supabase
                .from('brands')
                .insert([brandPayload])
                .select()
                .single()

            if (brandError) {
                console.error('Brand creation error', brandError)
                throw brandError
            }

            // 4. Link Profile (optional, if profiles.brand_id exists)
            const { error: profileError } = await supabase
                .from('profiles')
                .update({ brand_id: brandData.id })
                .eq('id', authData.user.id)

            if (profileError) console.warn('Profile link warning:', profileError)

            alert('Registration successful! Please login.')
            navigate('/login')

        } catch (err: any) {
            console.error(err)
            setError(err.message || 'An error occurred')
        } finally {
            setLoading(false)
            setUploading(false)
        }
    }

    return (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh', background: '#F3F4F6', padding: '2rem' }}>
            <div className="card" style={{ width: '100%', maxWidth: '450px', padding: '2rem' }}>
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
                            className="form-input"
                            style={{ width: '100%', padding: '0.75rem', borderRadius: '0.5rem', border: '1px solid #D1D5DB' }}
                        />
                    </div>

                    <div>
                        <label style={{ display: 'block', marginBottom: '0.5rem', fontSize: '0.875rem', fontWeight: 500 }}>Brand Logo</label>
                        {!logoPreview ? (
                            <div
                                onDragEnter={handleDrag} onDragLeave={handleDrag} onDragOver={handleDrag} onDrop={handleDrop}
                                style={{
                                    border: `2px dashed ${isDragging ? '#10B981' : '#D1D5DB'}`,
                                    borderRadius: '0.5rem',
                                    padding: '2rem',
                                    textAlign: 'center',
                                    background: isDragging ? '#ECFDF5' : 'white',
                                    transition: 'all 0.2s'
                                }}
                            >
                                <Upload size={32} color="#9CA3AF" style={{ marginBottom: '0.5rem' }} />
                                <p style={{ margin: 0, fontSize: '0.875rem', color: '#6B7280' }}>Drag & drop your logo here, or</p>
                                <label style={{ color: '#10B981', cursor: 'pointer', fontWeight: 500, fontSize: '0.875rem' }}>
                                    browse files
                                    <input type="file" accept="image/*" onChange={handleFileSelect} style={{ display: 'none' }} />
                                </label>
                            </div>
                        ) : (
                            <div style={{ position: 'relative', width: 'fit-content' }}>
                                <img src={logoPreview} alt="Preview" style={{ width: '100px', height: '100px', objectFit: 'contain', border: '1px solid #E5E7EB', borderRadius: '8px', padding: '4px' }} />
                                <button
                                    type="button"
                                    onClick={() => { setLogoFile(null); setLogoPreview(null); }}
                                    style={{ position: 'absolute', top: -8, right: -8, background: '#EF4444', color: 'white', borderRadius: '50%', border: 'none', width: '20px', height: '20px', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}
                                >
                                    <X size={12} />
                                </button>
                            </div>
                        )}
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
                        style={{
                            background: '#10B981', color: 'white', padding: '0.75rem', borderRadius: '0.5rem', border: 'none', fontWeight: 600, cursor: 'pointer', marginTop: '0.5rem',
                            display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px'
                        }}
                    >
                        {loading && <Loader2 size={18} className="spin" />}
                        {loading ? (uploading ? 'Uploading Logo...' : 'Creating Account...') : 'Register Brand'}
                    </button>
                </form>
                <div style={{ marginTop: '1.5rem', textAlign: 'center', fontSize: '0.875rem' }}>
                    <span style={{ color: '#6B7280' }}>Already have an account? </span>
                    <Link to="/login" style={{ color: '#10B981', textDecoration: 'none', fontWeight: 500 }}>Sign In</Link>
                </div>
            </div>
            <style>{`
        @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
        .spin { animation: spin 1s linear infinite; }
      `}</style>
        </div>
    )
}
