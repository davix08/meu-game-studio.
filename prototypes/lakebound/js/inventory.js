// PROTOTYPE - NOT FOR PRODUCTION
// Question: A disputa na barra, junto com a vontade de descobrir a próxima espécie, prende por uma sessão inteira?
// Date: 2026-11-11
// Inventory system: the bag and the collection count.
'use strict';
function bagValue(s) { return s.bag.reduce((a, f) => a + f.v, 0); }
function discovered(s) { return Object.keys(s.book).length; }
