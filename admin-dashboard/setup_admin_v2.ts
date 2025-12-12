import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://gwmcmlpuqummaumjloci.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3bWNtbHB1cXVtbWF1bWpsb2NpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0ODA3MzgsImV4cCI6MjA4MTA1NjczOH0.YejVHvXiO6i3mXfJ1Z9rXitTwSs4YdFXA8FuV9EigvY'

const supabase = createClient(supabaseUrl, supabaseKey)

async function setup() {
    console.log('Attempting to create/login admin...')

    // 1. Try Signing Up
    const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
        email: 'admin@ecoins.com',
        password: 'secure-admin-password-123'
    })

    let userId = signUpData.user?.id

    if (signUpError) {
        console.log('Signup result:', signUpError.message)
        // If already exists, try signing in to get ID
        if (signUpError.message.includes('already registered') || signUpError.message.includes('already exists')) {
            const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
                email: 'admin@ecoins.com',
                password: 'secure-admin-password-123'
            })
            if (signInData.user) {
                userId = signInData.user.id
                console.log('User already exists. Logged in.')
            } else {
                console.error('Could not login:', signInError?.message)
            }
        }
    } else {
        console.log('User created.')
    }

    if (userId) {
        console.log(`ADMIN_USER_ID:${userId}`)
    } else {
        console.error('Failed to get User ID')
    }
}

setup()
