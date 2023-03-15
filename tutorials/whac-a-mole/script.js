const size = 100;
const board = document.querySelector('#game');
const mole = document.createElement('div');
let hits = 0;
let strikes = 0;
let canHit = true;
let moleTimer;

mole.classList.add('mole');
mole.addEventListener('click', hit);
board.appendChild(mole);

function getRandomWithLimit(limit) {
    let random = Math.random();
    if (limit * random + size > limit) {
        random = getRandomWithLimit(limit);
    }
    return random;
}

function updatePosition() {
    let randX = getRandomWithLimit(board.clientWidth);
    let randY = getRandomWithLimit(board.clientHeight);
    mole.style = 'top: ' + randY * 100 + '%; left: ' + randX * 100 + '%;';

    moleTimer = setTimeout(() => {
        canHit = false;
        strikes++;
        mole.classList.add('disappear');

        setTimeout(() => {
            mole.classList.remove('disappear');
            update();
        }, 300);
    }, 1000);
}

function hit() {
    if (canHit) {
        canHit = false;
        hits++;
        mole.classList.add('hit');
        clearTimeout(moleTimer);
        setTimeout(() => {
            mole.classList.remove('hit');
            update();
        }, 400);
    }
}

function update() {
    canHit = true;
    updatePosition();
    document.querySelector('#status').innerHTML = 'Hits: ' + hits + ' Strikes: ' + strikes;
}

update();