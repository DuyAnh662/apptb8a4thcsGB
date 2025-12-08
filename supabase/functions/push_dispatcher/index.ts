// supabase/functions/push_dispatcher/index.ts
// Using jose library for proper JWT signing
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.3";
import { SignJWT, importPKCS8, importJWK } from "https://deno.land/x/jose@v4.14.4/index.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL") || "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const vapidPrivateKey = Deno.env.get("VAPID_PRIVATE_KEY") || "";
const vapidSubject = Deno.env.get("VAPID_SUBJECT") || "mailto:admin@example.com";
const vapidPublicKey = "BECwSj0xQaM3JXmGNAryUhNfQim1f0-h2cEEoSqDIrBfmYQi6g1aNUsCo6i1AN4k4-4LawmTOMrpTiM4cbn0KtA";

const supabase = createClient(supabaseUrl, supabaseServiceKey);

console.log("Init Push Dispatcher - V5 (jose library)");
console.log("VAPID keys:", !!vapidPrivateKey, !!vapidPublicKey);

function base64UrlDecode(str: string): Uint8Array {
    str = str.replace(/-/g, '+').replace(/_/g, '/');
    while (str.length % 4) str += '=';
    const binary = atob(str);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
        bytes[i] = binary.charCodeAt(i);
    }
    return bytes;
}

function base64UrlEncode(buffer: Uint8Array): string {
    let binary = '';
    for (let i = 0; i < buffer.length; i++) {
        binary += String.fromCharCode(buffer[i]);
    }
    return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

let privateKeyInstance: CryptoKey | null = null;

async function getPrivateKey(): Promise<CryptoKey> {
    if (privateKeyInstance) return privateKeyInstance;

    // Decode public key to get x, y
    const pubKeyBytes = base64UrlDecode(vapidPublicKey);
    const x = base64UrlEncode(pubKeyBytes.slice(1, 33));
    const y = base64UrlEncode(pubKeyBytes.slice(33, 65));

    // Create JWK
    const jwk = {
        kty: "EC",
        crv: "P-256",
        x: x,
        y: y,
        d: vapidPrivateKey,
    };

    console.log("Importing JWK with x:", x.substring(0, 10) + "..., y:", y.substring(0, 10) + "...");

    privateKeyInstance = await importJWK(jwk, "ES256");
    return privateKeyInstance;
}

async function createVapidAuth(audience: string): Promise<string> {
    const key = await getPrivateKey();

    const jwt = await new SignJWT({})
        .setProtectedHeader({ alg: "ES256", typ: "JWT" })
        .setAudience(audience)
        .setExpirationTime("12h")
        .setSubject(vapidSubject)
        .sign(key);

    return `vapid t=${jwt}, k=${vapidPublicKey}`;
}

async function sendPush(subscription: any): Promise<boolean> {
    try {
        const endpoint = subscription.endpoint;
        const url = new URL(endpoint);
        const audience = `${url.protocol}//${url.host}`;

        console.log("Target:", endpoint.substring(0, 60));

        const auth = await createVapidAuth(audience);
        console.log("Auth header created");

        const response = await fetch(endpoint, {
            method: "POST",
            headers: {
                "Authorization": auth,
                "TTL": "86400",
                "Content-Length": "0",
            },
        });

        console.log("Status:", response.status);

        if (response.status >= 200 && response.status < 300) {
            return true;
        } else if (response.status === 410 || response.status === 404) {
            await supabase.from("push_subscriptions").delete().eq("endpoint", endpoint);
            return false;
        } else {
            const text = await response.text();
            console.error("Failed:", response.status, text);
            return false;
        }
    } catch (err) {
        console.error("Error:", err);
        return false;
    }
}

serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", {
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization",
            },
        });
    }

    try {
        const body = await req.json();
        const record = body.record;

        if (!record) {
            return new Response(JSON.stringify({ error: "No record" }), {
                status: 400,
                headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
            });
        }

        const { data: subs, error } = await supabase.from("push_subscriptions").select("*");

        if (error) {
            return new Response(JSON.stringify({ error: error.message }), {
                status: 500,
                headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
            });
        }

        console.log(`Subs: ${subs?.length || 0}`);

        let sent = 0;
        for (const sub of subs || []) {
            if (await sendPush(sub)) sent++;
        }

        return new Response(JSON.stringify({
            success: true,
            sent,
            total: subs?.length || 0
        }), {
            headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
        });

    } catch (err) {
        console.error("Error:", err);
        return new Response(JSON.stringify({ error: String(err) }), {
            status: 500,
            headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }
        });
    }
});
