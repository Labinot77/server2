// ============================================================================
//  Crafting bench UI
//  Left: searchable recipe list. Right: selected recipe, materials (have/need), amount + craft.
//  The craft request is a normal MoveItem from the 'Crafting' inventory; the server re-validates
//  the recipe, rep, amount and materials.
// ============================================================================
let Crafting = { Selected: false, Amount: 1, Search: '', Busy: false };

const GetRecipes = () => Object.values(OtherInvData.Items || {}).filter(v => v && v.Item && ItemsList[v.Item]);
const GetRecipeBySlot = (Slot) => GetRecipes().find(v => v.Slot == Slot);
const GetRecipeCraft = (Recipe) => GetItemData(Recipe.Item, Recipe.CustomType).Craft || [];

const CountPlayerItem = (ItemName, CustomType) => {
    let Total = 0;
    for (const Item of Object.values(MyInventory)) {
        if (Item && Item.Item == ItemName && (!CustomType || Item.CustomType == CustomType)) Total += Number(Item.Amount) || 0;
    }
    return Total;
};

// How many times can this recipe be crafted with what the player carries (capped by the bench).
const GetMaxCrafts = (Recipe) => {
    if (Recipe.Locked) return 0;
    let Max = Number(Recipe.Amount) || 1;
    for (const Need of GetRecipeCraft(Recipe)) Max = Math.min(Max, Math.floor(CountPlayerItem(Need.Item, Need.CustomType) / Need.Amount));
    return Math.max(0, Max);
};

const EscapeHtml = (Text) => String(Text ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const ItemImgSrc = (Data) => Data.IsExternImage ? Data.Image : `./img/items/${Data.Image}`;

const BuildCraftingPanel = (Grid) => {
    Grid.addClass('is-crafting');
    Grid.html(`<div class="craft-ui">
        <div class="craft-list-wrap">
            <div class="craft-search"><input type="text" id="craft-search" placeholder="Zoek recept..." spellcheck="false"></div>
            <div class="craft-list"></div>
            <div class="craft-rep">Crafting rep <span>${Number(OtherInvData.CraftingRep || 0).toLocaleString('nl-NL')}</span></div>
        </div>
        <div class="craft-detail"></div>
    </div>`);

    Crafting.Search = '';
    const Recipes = GetRecipes();
    if (!GetRecipeBySlot(Crafting.Selected)) Crafting.Selected = (Recipes.find(r => !r.Locked) || Recipes[0] || {}).Slot || false;
    Crafting.Amount = 1;
    RenderCraftList();
    RenderCraftDetail();
};

const RenderCraftList = () => {
    const List = $('.craft-list').empty();
    const Search = Crafting.Search.toLowerCase();
    const Recipes = GetRecipes().sort((a, b) => (a.Locked - b.Locked) || ((GetMaxCrafts(b) > 0) - (GetMaxCrafts(a) > 0)) || (a.Slot - b.Slot));

    let Shown = 0;
    for (const Recipe of Recipes) {
        const Data = GetItemData(Recipe.Item, Recipe.CustomType);
        if (Search && !String(Data.Label).toLowerCase().includes(Search)) continue;
        Shown++;
        const Max = GetMaxCrafts(Recipe);
        const State = Recipe.Locked ? 'locked' : (Max > 0 ? 'ready' : 'missing');
        const Output = (Recipe.Multiplier || 1) > 1 ? `<span class="craft-row-mult">x${Recipe.Multiplier}</span>` : '';
        List.append(`<div class="craft-row ${State} ${Recipe.Slot == Crafting.Selected ? 'selected' : ''}" data-recipe="${Recipe.Slot}">
            <div class="craft-row-img"><img src="${ItemImgSrc(Data)}">${Output}</div>
            <div class="craft-row-text">
                <div class="craft-row-name">${EscapeHtml(Data.Label)}</div>
                <div class="craft-row-sub">${Recipe.Locked ? `Vereist ${Recipe.RequiredRep} rep` : (Max > 0 ? `Kan ${Max}x maken` : 'Materialen ontbreken')}</div>
            </div>
            <div class="craft-row-state"></div>
        </div>`);
    }
    if (!Shown) List.append(`<div class="craft-empty">Geen recepten gevonden.</div>`);
};

const RenderCraftDetail = () => {
    const Detail = $('.craft-detail').empty();
    const Recipe = GetRecipeBySlot(Crafting.Selected);
    if (!Recipe) return Detail.html(`<div class="craft-empty">Selecteer een recept.</div>`);

    const Data = GetItemData(Recipe.Item, Recipe.CustomType);
    const Max = GetMaxCrafts(Recipe);
    Crafting.Amount = Math.max(1, Math.min(Crafting.Amount, Math.max(Max, 1)));
    const Mult = Recipe.Multiplier || 1;

    let Materials = '';
    for (const Need of GetRecipeCraft(Recipe)) {
        const NeedData = GetItemData(Need.Item, Need.CustomType);
        const Have = CountPlayerItem(Need.Item, Need.CustomType), Total = Need.Amount * Crafting.Amount;
        Materials += `<div class="craft-mat ${Have >= Total ? 'ok' : 'short'}">
            <img src="${ItemImgSrc(NeedData)}">
            <div class="craft-mat-name">${EscapeHtml(NeedData.Label)}</div>
            <div class="craft-mat-count"><b>${Have}</b> / ${Total}</div>
        </div>`;
    }

    const CanCraft = !Recipe.Locked && Max >= Crafting.Amount && !Crafting.Busy;
    Detail.html(`
        <div class="craft-hero">
            <div class="craft-hero-img"><img src="${ItemImgSrc(Data)}"></div>
            <div class="craft-hero-text">
                <div class="craft-hero-name">${EscapeHtml(Data.Label)}${Mult > 1 ? ` <span>x${Mult}</span>` : ''}</div>
                <div class="craft-hero-desc">${EscapeHtml(Data.Description || '')}</div>
                <div class="craft-hero-meta">
                    <span>Gewicht ${((Data.Weight || 0) * Mult).toFixed(1)}</span>
                    ${Recipe.Locked ? `<span class="locked">Vergrendeld · ${Recipe.RequiredRep} rep nodig</span>` : `<span>Max ${Max}x</span>`}
                </div>
            </div>
        </div>
        <div class="craft-section-title">Benodigdheden</div>
        <div class="craft-mats">${Materials || '<div class="craft-empty">Geen materialen nodig.</div>'}</div>
        <div class="craft-actions">
            <div class="craft-stepper ${Recipe.Locked ? 'disabled' : ''}">
                <button data-step="-1">−</button>
                <input type="number" id="craft-amount" min="1" value="${Crafting.Amount}">
                <button data-step="1">+</button>
                <button class="craft-max" data-step="max">MAX</button>
            </div>
            <button class="craft-btn ${CanCraft ? '' : 'disabled'}" id="craft-go">${Crafting.Busy ? 'Bezig...' : (Recipe.Locked ? 'Vergrendeld' : `Craft ${Crafting.Amount * Mult}x`)}</button>
        </div>`);
};

const RefreshCraftingPanel = () => {
    if (!InventoryOpen || OtherInvData.Type != 'Crafting' || !$('.craft-ui').length) return;
    RenderCraftList();
    RenderCraftDetail();
};

const DoCraft = async () => {
    const Recipe = GetRecipeBySlot(Crafting.Selected);
    if (!Recipe || Recipe.Locked || Crafting.Busy) return;
    const Amount = Crafting.Amount;
    if (GetMaxCrafts(Recipe) < Amount) return InventoryLog("[Error]: Je hebt niet genoeg materialen.");

    const Output = { Item: Recipe.Item, CustomType: Recipe.CustomType, Amount: Amount * (Recipe.Multiplier || 1) };
    const ToSlot = FindTargetSlot('player', Output);
    if (!ToSlot) return InventoryLog("[Error]: Je hebt geen plek meer.");

    const ItemWeight = (ItemsList[Recipe.Item].Weight || 0) * Output.Amount;
    if (CalculateTotalInvWeight(MyInventory) + ItemWeight > GetPlayerMaxWeight(MyInventory)) return InventoryLog("[Error]: Dit is te zwaar.");

    Crafting.Busy = true;
    RenderCraftDetail();
    $.post(`https://fw-inventory/MoveItem`, JSON.stringify({
        FromInv: 'Crafting', ToInv: 'player',
        FromSlot: Recipe.Slot, ToSlot,
        Amount, FromItem: Recipe.Item, FromType: Recipe.CustomType,
        Crafting: OtherInvData.Crafting,
        FromAmount: Recipe.Amount,
    }));
    // Unlock after the server has had time to answer (RefreshPlayer re-renders with real data).
    setTimeout(() => { Crafting.Busy = false; RefreshCraftingPanel(); }, 700);
};

$(document).on('click', '.craft-row', function() {
    Crafting.Selected = Number($(this).data('recipe'));
    Crafting.Amount = 1;
    $('.craft-row').removeClass('selected');
    $(this).addClass('selected');
    RenderCraftDetail();
});

$(document).on('input', '#craft-search', function() {
    Crafting.Search = $(this).val() || '';
    RenderCraftList();
});

$(document).on('click', '.craft-stepper button', function() {
    const Recipe = GetRecipeBySlot(Crafting.Selected);
    if (!Recipe || Recipe.Locked) return;
    const Step = $(this).data('step'), Max = Math.max(1, GetMaxCrafts(Recipe));
    Crafting.Amount = Step == 'max' ? Max : Math.max(1, Math.min(Max, Crafting.Amount + Number(Step)));
    RenderCraftDetail();
});

$(document).on('change', '#craft-amount', function() {
    const Recipe = GetRecipeBySlot(Crafting.Selected);
    Crafting.Amount = Math.max(1, Math.min(Math.max(1, GetMaxCrafts(Recipe || {})), Math.floor(Number($(this).val()) || 1)));
    RenderCraftDetail();
});

$(document).on('click', '#craft-go', function() { DoCraft(); });

// Typing in the search/amount box must not trigger inventory hotkeys.
$(document).on('keydown', '.craft-ui input', function(e) {
    e.stopPropagation();
    if (e.key == 'Enter' && this.id == 'craft-amount') $(this).trigger('change');
});
