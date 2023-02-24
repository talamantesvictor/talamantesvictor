let lastTime = Date.now();
let timeSinceLastMovement = 0;
let square = 10;
let currentPosition = {x: 0, y: 0};
let direction = {x: 1, y: 0};
let food = {x: 0, y: 0};
let tail = [];
let isGameOver = false;
let canvas = document.querySelector("#game");
let ctx = canvas.getContext("2d");

function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.fillStyle = "#ffffff";

    ctx.fillRect(currentPosition.x, currentPosition.y, square, square);

    tail.forEach(element => {
        ctx.fillRect(element.x, element.y, square, square);
    });

    ctx.fillStyle = "#ff0000";
    ctx.fillRect(food.x, food.y, square, square);
}

function gameLoop() {
    if (!checkWallCollision()) {
        draw();

        let currentTime = Date.now();
        timeSinceLastMovement += currentTime - lastTime;
        lastTime = currentTime;

        if (timeSinceLastMovement > 200) {
            timeSinceLastMovement = 0;
            updateTail();
            currentPosition.x += square * direction.x;
            currentPosition.y += square * direction.y;
            checkFood();
        }

        window.requestAnimationFrame(gameLoop);
    }
    else {
        canvas.classList.add('over');
    }
}

function changeDirection(e) {
    let code = e.keyCode;
    switch (code) {
        case 37: resetDirections(); direction.x = -1; break;    // Left
        case 38: resetDirections(); direction.y = -1; break;    // Up
        case 39: resetDirections(); direction.x = 1; break;     // Right
        case 40: resetDirections(); direction.y = 1; break;     // Down
    }
}

function resetDirections() {
    direction.x = 0;
    direction.y = 0;
}

function checkWallCollision() {
    return  currentPosition.x < 0 || 
            currentPosition.x > canvas.width - square || 
            currentPosition.y < 0 || 
            currentPosition.y > canvas.height - square;
}

function updateTail(index) {
    for (let i = tail.length - 1; i >= 0; i--) {
        if (i == 0) {
            tail[i].x = currentPosition.x;
            tail[i].y = currentPosition.y;
        }
        else {
            tail[i].x = tail[i-1].x
            tail[i].y = tail[i-1].y
        }
    }
}

function addFood() {
    let isValid = true;
    let randX = Math.floor(Math.random() * (canvas.width / square));
    let randY = Math.floor(Math.random() * (canvas.height / square));

    randX *= square;
    randY *= square;

    if (currentPosition.x == randX && currentPosition.y == randY) {
        isValid = false;
    }
    tail.forEach(element => {
        isValid = isValid && (element.x != randX || element.y != randY);
    });

    if (!isValid) {
        addFood();
    }
    else {
        food = {x: randX, y: randY};
    }
}

function checkFood() {
    if (currentPosition.x == food.x && currentPosition.y == food.y) {
        tail.push({x: currentPosition.x, y: currentPosition.y });
        addFood();
    }
}

addFood();
gameLoop();

window.addEventListener('keydown', changeDirection);