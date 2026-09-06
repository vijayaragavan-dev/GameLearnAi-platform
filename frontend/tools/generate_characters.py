import os

# 24 characters with distinct visual identities
characters = [
    # INITIATE
    ("initiates_spark", "Nova Spark", "#8B5CF6", "INITIATE", "spark"),
    ("initiates_scout", "Byte Scout", "#22D3EE", "INITIATE", "scout"),
    # COMMON
    ("common_lumen_coder", "Lumen Coder", "#A78BFA", "COMMON", "coder"),
    ("common_logic_leaf", "Logic Leaf", "#34D399", "COMMON", "leaf"),
    ("common_pixel_pilot", "Pixel Pilot", "#38BDF8", "COMMON", "pilot"),
    ("common_syntax_scout", "Syntax Scout", "#FBBF24", "COMMON", "syntax"),
    ("common_bit_bloom", "Bit Bloom", "#F472B6", "COMMON", "bloom"),
    ("common_query_quill", "Query Quill", "#818CF8", "COMMON", "quill"),
    ("common_loop_lynx", "Loop Lynx", "#FB923C", "COMMON", "lynx"),
    # RARE
    ("rare_net_ranger", "Net Ranger", "#22D3EE", "RARE", "net"),
    ("rare_os_orbit", "Orbit Keeper", "#8B5CF6", "RARE", "orbit"),
    ("rare_structure_sentinel", "Structure Sentinel", "#34D399", "RARE", "structure"),
    ("rare_data_weaver", "Data Weaver", "#FACC15", "RARE", "weaver"),
    ("rare_code_captain", "Code Captain", "#F97316", "RARE", "captain"),
    ("rare_signal_sage", "Signal Sage", "#38BDF8", "RARE", "signal"),
    # EPIC
    ("epic_algo_sage", "Algo Sage", "#8B5CF6", "EPIC", "algo"),
    ("epic_network_nexus", "Network Nexus", "#22D3EE", "EPIC", "nexus"),
    ("epic_os_titan", "OS Titan", "#FACC15", "EPIC", "titan"),
    ("epic_program_archon", "Program Archon", "#A78BFA", "EPIC", "archon"),
    ("epic_query_prime", "Query Prime", "#34D399", "EPIC", "prime"),
    # LEGENDARY
    ("legendary_db_oracle", "Oracle of Data", "#FACC15", "LEGENDARY", "oracle"),
    ("legendary_code_sovereign", "Code Sovereign", "#8B5CF6", "LEGENDARY", "sovereign"),
    ("legendary_network_warden", "Network Warden", "#22D3EE", "LEGENDARY", "warden"),
    ("legendary_kernel_legend", "Kernel Legend", "#F472B6", "LEGENDARY", "kernel"),
]

# Map rarity to accent colors
rarity_colors = {
    "INITIATE": ("#475569", "#64748B"),
    "COMMON": ("#64748B", "#94A3B8"),
    "RARE": ("#22D3EE", "#0E7490"),
    "EPIC": ("#8B5CF6", "#5B21B6"),
    "LEGENDARY": ("#FACC15", "#B45309"),
}

def generate_svg(code, name, color, rarity, motif):
    accent, accent2 = rarity_colors.get(rarity, ("#8B5CF6", "#5B21B6"))
    # Unique accessory based on motif
    # We'll vary the accessory shape: hat, glasses, headset, etc.
    accessory = ""
    if motif in ["spark", "coder", "archon", "sovereign"]:
        accessory = '<ellipse cx="100" cy="55" rx="35" ry="12" fill="{ac}" opacity="0.9"/><rect x="85" y="40" width="30" height="18" rx="4" fill="{ac}" opacity="0.95"/>'.format(ac=accent)
    elif motif in ["scout", "pilot", "captain", "warden"]:
        accessory = '<path d="M70 60 Q100 35 130 60 L125 65 Q100 45 75 65 Z" fill="{ac}" opacity="0.95"/>'.format(ac=accent)
    elif motif in ["leaf", "bloom", "quill", "leaf"]:
        accessory = '<path d="M100 35 Q115 45 100 55 Q85 45 100 35" fill="{ac}" opacity="0.9"/><circle cx="100" cy="45" r="6" fill="white" opacity="0.9"/>'.format(ac=accent)
    elif motif in ["net", "nexus", "signal", "warden"]:
        accessory = '<g opacity="0.9"><circle cx="85" cy="50" r="8" fill="none" stroke="{ac}" stroke-width="2"/><circle cx="115" cy="50" r="8" fill="none" stroke="{ac}" stroke-width="2"/><line x1="93" y1="50" x2="107" y2="50" stroke="{ac}" stroke-width="2"/></g>'.format(ac=accent)
    elif motif in ["orbit", "titan", "kernel"]:
        accessory = '<circle cx="100" cy="45" r="18" fill="none" stroke="{ac}" stroke-width="2" stroke-dasharray="4 3" opacity="0.8"/><circle cx="100" cy="45" r="4" fill="{ac}"/>'.format(ac=accent)
    elif motif in ["structure", "algo", "prime"]:
        accessory = '<rect x="88" y="38" width="24" height="14" rx="3" fill="{ac}" opacity="0.9"/><line x1="92" y1="42" x2="108" y2="42" stroke="white" stroke-width="1.5" opacity="0.7"/><line x1="92" y1="47" x2="104" y2="47" stroke="white" stroke-width="1.5" opacity="0.7"/>'.format(ac=accent)
    else:
        accessory = '<circle cx="100" cy="45" r="10" fill="{ac}" opacity="0.85"/>'.format(ac=accent)

    # Body varies by rarity
    body = ""
    if rarity == "LEGENDARY":
        body = '<path d="M85 110 Q100 125 115 110 L110 140 Q100 145 90 140 Z" fill="{c}" opacity="0.95"/><path d="M90 120 L85 135 L95 130 Z" fill="{c2}" opacity="0.9"/><path d="M110 120 L115 135 L105 130 Z" fill="{c2}" opacity="0.9"/>'.format(c=accent, c2=accent2)
    elif rarity == "EPIC":
        body = '<path d="M88 115 Q100 128 112 115 L108 138 Q100 142 92 138 Z" fill="{c}" opacity="0.92"/>'.format(c=accent)
    else:
        body = '<rect x="88" y="115" width="24" height="22" rx="6" fill="{c}" opacity="0.9"/>'.format(c=accent)

    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">
  <defs>
    <radialGradient id="bg" cx="50%" cy="40%" r="70%">
      <stop offset="0%" stop-color="{accent}" stop-opacity="0.18"/>
      <stop offset="100%" stop-color="{accent2}" stop-opacity="0.04"/>
    </radialGradient>
  </defs>
  <circle cx="100" cy="100" r="92" fill="url(#bg)" stroke="{accent}" stroke-opacity="0.12" stroke-width="1.5"/>
  <!-- Body -->
  {body}
  <!-- Head -->
  <circle cx="100" cy="85" r="32" fill="#F1F5F9" stroke="{accent}" stroke-opacity="0.25" stroke-width="1.5"/>
  <circle cx="100" cy="85" r="29" fill="white" opacity="0.95"/>
  <!-- Eyes -->
  <ellipse cx="90" cy="82" rx="5" ry="6" fill="#0F172A"/>
  <ellipse cx="110" cy="82" rx="5" ry="6" fill="#0F172A"/>
  <circle cx="91.5" cy="80" r="1.8" fill="white" opacity="0.9"/>
  <circle cx="111.5" cy="80" r="1.8" fill="white" opacity="0.9"/>
  <!-- Smile -->
  <path d="M92 95 Q100 102 108 95" fill="none" stroke="#0F172A" stroke-width="1.8" stroke-linecap="round" opacity="0.85"/>
  <!-- Accessory -->
  {accessory}
  <!-- Rarity accent dot -->
  <circle cx="100" cy="150" r="3.5" fill="{accent}" opacity="0.9"/>
</svg>
'''
    return svg

os.makedirs("frontend/assets/characters", exist_ok=True)
for code, name, color, rarity, motif in characters:
    svg_content = generate_svg(code, name, color, rarity, motif)
    # assetKey in backend is like characters/nova_spark, characters/lumen_coder etc.
    # Map code to assetKey: code uses underscores, assetKey uses same but with slash
    # For our generated files, use the backend assetKey mapping: characters/<code_without_prefix>
    # But backend assetKey is like characters/nova_spark, characters/lumen_coder etc.
    # Our code is like initiates_spark -> assetKey characters/nova_spark (mismatch). Use mapping table.
    # For simplicity, generate file for both: code and assetKey
    # We'll generate for the backend assetKey directly by mapping.
    pass

# Map backend assetKeys to our generated codes
backend_to_file = {
    "characters/nova_spark": "initiates_spark",
    "characters/byte_scout": "initiates_scout",
    "characters/lumen_coder": "common_lumen_coder",
    "characters/logic_leaf": "common_logic_leaf",
    "characters/pixel_pilot": "common_pixel_pilot",
    "characters/syntax_scout": "common_syntax_scout",
    "characters/bit_bloom": "common_bit_bloom",
    "characters/query_quill": "common_query_quill",
    "characters/loop_lynx": "common_loop_lynx",
    "characters/net_ranger": "rare_net_ranger",
    "characters/orbit_keeper": "rare_os_orbit",
    "characters/structure_sentinel": "rare_structure_sentinel",
    "characters/data_weaver": "rare_data_weaver",
    "characters/code_captain": "rare_code_captain",
    "characters/signal_sage": "rare_signal_sage",
    "characters/algo_sage": "epic_algo_sage",
    "characters/network_nexus": "epic_network_nexus",
    "characters/os_titan": "epic_os_titan",
    "characters/program_archon": "epic_program_archon",
    "characters/query_prime": "epic_query_prime",
    "characters/oracle_of_data": "legendary_db_oracle",
    "characters/code_sovereign": "legendary_code_sovereign",
    "characters/network_warden": "legendary_network_warden",
    "characters/kernel_legend": "legendary_kernel_legend",
}

# Create a dict for quick lookup of character data by code
char_dict = {c[0]: c for c in characters}

for asset_key, code in backend_to_file.items():
    if code not in char_dict:
        continue
    _, name, color, rarity, motif = char_dict[code]
    svg = generate_svg(code, name, color, rarity, motif)
    filename = asset_key.split("/")[-1] + ".svg"
    path = os.path.join("frontend/assets/characters", filename)
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"Generated {path} ({len(svg)} bytes)")

# Also generate for the code-named files as fallback
for code, name, color, rarity, motif in characters:
    svg = generate_svg(code, name, color, rarity, motif)
    filename = code + ".svg"
    path = os.path.join("frontend/assets/characters", filename)
    if not os.path.exists(path):
        with open(path, "w", encoding="utf-8") as f:
            f.write(svg)
        print(f"Generated fallback {path}")

print("Done")
