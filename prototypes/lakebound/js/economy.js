// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Economy system: selling the bag, buying and equipping gear, using items.
'use strict';
function sellAll(s) {
  if (!s.bag.length) { toast('A bolsa está vazia.'); return; }
  const v = bagValue(s), n = s.bag.length;
  s.coins += v; s.bag = []; s.stats.earned += v;
  toast(`Vendeu ${n} peixe${n > 1 ? 's' : ''} por ${v} moedas!`); sfx.coin(); saveGame(s);
}
/** Buys or equips a rod or bait. kind: 'rod' | 'bait'. */
function shopGear(s, kind, item) {
  const owned = kind === 'rod' ? s.rodsOwned : s.baitsOwned;
  if (owned.includes(item.id)) { if (kind === 'rod') s.rod = item.id; else s.bait = item.id; toast(`${item.name} equipada.`); sfx.click(); saveGame(s); return; }
  if (s.level < item.level) { toast(`Liberada no nível ${item.level}.`); return; }
  if (s.coins < item.price) { toast('Moedas insuficientes.'); sfx.deny(); return; }
  s.coins -= item.price; owned.push(item.id);
  if (kind === 'rod') s.rod = item.id; else s.bait = item.id;
  toast(`Comprou ${item.name}!`); sfx.coin(); saveGame(s);
}
function shopItem(s, item) {
  if (s.level < item.level) { toast(`Liberado no nível ${item.level}.`); return; }
  if (s.coins < item.price) { toast('Moedas insuficientes.'); sfx.deny(); return; }
  s.coins -= item.price;
  if (item.id === 'lanche') s.snacks++; else s.luckBaits++;
  toast(`Comprou ${item.name}!`); sfx.coin(); saveGame(s);
}
function eatSnack(s) {
  if (!s.snacks) { toast('Sem lanches. Compre na loja.'); return; }
  if (s.energy >= 100) { toast('A energia já está cheia.'); return; }
  s.snacks--; s.energy = Math.min(100, s.energy + tune.snackEnergy); toast(`Lanche! +${tune.snackEnergy} de energia.`); sfx.eat(); saveGame(s);
}
function useLuck(s) {
  if (!s.luckBaits) { toast('Sem iscas da sorte. Compre na loja (nível 2).'); return; }
  s.luckBaits--; s.luckLeft += tune.luckMinutes; toast('Isca da sorte ativa: mais peixes raros!'); sfx.luck(); saveGame(s);
}
