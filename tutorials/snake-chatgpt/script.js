const gameContainer = document.querySelector('.game-container');
const snake = document.querySelector('.snake');
const food = document.querySelector('.food');

let snakeX = 0;
let snakeY = 0;
let foodX = 0;
let foodY = 0;
let snakeSpeed = 20; // Pixels per movement
let snakeDirection = 'right';
let snakeBody = [{ x: snakeX, y: snakeY }];

function getRandomPosition() {
    return Math.floor(Math.random() * 15) * 20; // 20px grid
}

function updateFoodPosition() {
    foodX = getRandomPosition();
    foodY = getRandomPosition();
    food.style.left = foodX + 'px';
    food.style.top = foodY + 'px';
}

function moveSnake() {
    if (snakeDirection === 'right') {
        snakeX += snakeSpeed;
    } else if (snakeDirection === 'left') {
        snakeX -= snakeSpeed;
    } else if (snakeDirection === 'up') {
        snakeY -= snakeSpeed;
    } else if (snakeDirection === 'down') {
        snakeY += snakeSpeed;
    }

    // Update the snake's body
    snakeBody.unshift({ x: snakeX, y: snakeY });
    if (snakeX === foodX && snakeY === foodY) {
        // Snake ate the food
        updateFoodPosition();
        // Increase snake length
        // This adds a new segment to the snake's body
        snakeBody.push({});
    } else {
        snakeBody.pop();
    }

    // Check for collisions
    if (
        snakeX < 0 ||
        snakeX >= gameContainer.offsetWidth ||
        snakeY < 0 ||
        snakeY >= gameContainer.offsetHeight ||
        isCollisionWithSelf()
    ) {
        // Game over logic
        // Reset snake position and body
        snakeX = 0;
        snakeY = 0;
        snakeBody = [{ x: snakeX, y: snakeY }];
        snakeDirection = 'right';
    }

    // Update snake's position visually
    snake.style.left = snakeX + 'px';
    snake.style.top = snakeY + 'px';
}

function isCollisionWithSelf() {
    for (let i = 1; i < snakeBody.length; i++) {
        if (snakeX === snakeBody[i].x && snakeY === snakeBody[i].y) {
            return true;
        }
    }
    return false;
}

document.addEventListener('keydown', (event) => {
    if (event.key === 'ArrowRight' && snakeDirection !== 'left') {
        snakeDirection = 'right';
    } else if (event.key === 'ArrowLeft' && snakeDirection !== 'right') {
        snakeDirection = 'left';
    } else if (event.key === 'ArrowUp' && snakeDirection !== 'down') {
        snakeDirection = 'up';
    } else if (event.key === 'ArrowDown' && snakeDirection !== 'up') {
        snakeDirection = 'down';
    }
});

updateFoodPosition();
setInterval(moveSnake, 150); // Update snake position every 150 milliseconds
