import { createClient } from '@supabase/supabase-js'
import dotenv from 'dotenv'

dotenv.config()

const supabaseUrl = process.env.VITE_SUPABASE_URL
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseKey) {
    console.error('Missing Supabase credentials in .env')
    process.exit(1)
}

const supabase = createClient(supabaseUrl, supabaseKey)

async function createAdmin() {
    const email = 'admin@ecoins.com'
    const password = 'secure-admin-password-123'

    console.log(`Creating admin user: ${email}...`)

    const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
            data: {
                role: 'brand_admin',
                name: 'Super Admin'
            }
        }
    })

    if (error) {
        console.error('Error creating admin:', error.message)
    } else {
        console.log('Admin user created successfully!')
        console.log('User ID:', data.user?.id)
        console.log('NOTE: If email confirmation is enabled, you must confirm manually or disable it in Supabase Auth settings.')
    }
}

createAdmin()
