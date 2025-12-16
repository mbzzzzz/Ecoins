# Brand Onboarding Portal & Carbon Tracking Widget

## Overview
The **Eco Rewards Brand Portal** is a dedicated web interface that empowers partner brands to manage their sustainability campaigns, track their environmental impact, and engage with the Eco Rewards community. This feature seamlessly integrates the brand's contributions into the Eco Rewards ecosystem and provides them with tools to showcase their impact on their own platforms.

## Key Features

### 1. Brand Dashboard & Onboarding
*   **Sign Up & Profile Management**: Brands can sign up and create a detailed profile, including their brand name, description, industry, and contact information.
*   **Drag & Drop Logo Upload**: An intuitive drag-and-drop interface allows brands to easily upload and update their logos, ensuring consistent branding across the Eco Rewards app and widgets.
*   **Theme Integration**: The portal mirrors the sleek, modern design of the Eco Rewards mobile app, utilizing the same color palette (Primary Green `#10B981`) and typography (Inter/Outfit) for a cohesive user experience.

### 2. Campaign & Offer Management
*   **Launch Offers**: Brands can create and launch new reward offers (e.g., "15% off for 500 points") directly from their dashboard.
*   **Generate Discount Codes**: The system automatically generates unique or reusable discount codes that are distributed to users upon redemption.
*   **Edit & Manage**: Brands have full control to edit active offers, pause campaigns, or update terms and conditions in real-time.

### 3. Real-time Carbon Footprint Widget (API)
*   **Embeddable JavaScript Widget**: Brands receive a generated Javascript snippet (e.g., `<script src="..."></script>`) that they can copy and paste into their own website's HTML.
*   **Real-time Impact Tracking**:
    *   This widget displays a **Carbon Saving Progress Bar** on the brand's external website.
    *   **Mechanism**: When an Eco Rewards user redeems points for an offer from "Brand X", the system calculates the associated carbon savings (based on the eco-action performed to earn those points).
    *   **Automatic Updates**: These savings are immediately attributed to "Brand X" in the database. The embedded widget fetches this data in real-time, updating the progress bar to reflect the total carbon saved by the brand's community engagement.
*   **API Key Integration**: Each brand gets a unique public API key to securely fetch their specific impact stats without exposing sensitive data.

## Technical Implementation Workflow

### Database Schema (Supabase)
1.  **`brands` Table**: `id`, `name`, `description`, `logo_url`, `api_key` (unique), `total_carbon_saved`, `website_url`.
2.  **`offers` Table**: `id`, `brand_id`, `title`, `cost_points`, `discount_code`, `is_active`.
3.  **`redemptions` Table**: `id`, `user_id`, `offer_id`, `carbon_value_snapshot` (how much carbon this redemption represents).

### Workflow
1.  **Brand Admin** logs into the portal (web view).
2.  **Onboarding**: Admin edits profile and uploads logo (saved to Supabase Storage `brands/logos`).
3.  **Offer Creation**: Admin posts a "Buy One Get One" offer. This creates a row in the `offers` table.
4.  **Widget Setup**: Admin goes to "Settings" -> "Integrations".
    *   System generates a snippet:
        ```html
        <div id="eco-rewards-widget"></div>
        <script src="https://api.ecoins.com/widget.js?key=BRAND_API_KEY"></script>
        ```
5.  **User Action**: A user on the mobile app redeems 500 points for this offer.
    *   Backend triggers: `total_carbon_saved` for this brand increases by the user's saved carbon amount.
6.  **Website Update**: The script on the brand's website polls the API, sees the new total, and animates the progress bar forward.

## Aesthetic Style
*   **Visuals**: Clean, green-focused UI with glassmorphism cards for stats.
*   **Charts**: Interactive progress rings and line charts showing impact over time.
*   **Animations**: Smooth transitions when updating profile data or tracking live redemption events.

---
**Next Steps for Implementation**:
1.  Create `brand_portal` screens (Dashboard, Edit Profile, Offers, Widget settings).
2.  Implement the `brands` and `offers` tables in Supabase.
3.  Build the public-facing Javascript widget endpoint (Function or simple hosted JS file).
