document.addEventListener('DOMContentLoaded', () => {
    // --- DOM Elements ---
    const userList = document.getElementById('user-list');
    const messageDisplay = document.getElementById('message-display');
    const messageForm = document.getElementById('message-form');
    const messageInput = document.getElementById('message-input');
    const recipientInput = document.getElementById('recipient-input');
    const currentUserDisplay = document.getElementById('current-user-display');
    const canvas = document.getElementById('encryption-canvas');
    const ctx = canvas.getContext('2d');
    const vizStatus = document.getElementById('viz-status');

    // --- State ---
    let currentUser = '';
    let selectedUser = '';
    let messagePollingInterval;

    // --- Visualization ---
    function playEncryptionAnimation(operation) {
        let progress = 0;
        const color = operation === 'encrypt' ? '#4a90e2' : '#2ecc71';
        vizStatus.textContent = operation === 'encrypt' ? 'Encrypting...' : 'Decrypting...';

        const animation = setInterval(() => {
            progress += 5;
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            // Outer circle
            ctx.beginPath();
            ctx.arc(100, 100, 80, 0, 2 * Math.PI);
            ctx.strokeStyle = '#ddd';
            ctx.stroke();

            // Progress arc
            ctx.beginPath();
            ctx.arc(100, 100, 70, -0.5 * Math.PI, (progress / 100) * 2 * Math.PI - 0.5 * Math.PI);
            ctx.lineWidth = 20;
            ctx.strokeStyle = color;
            ctx.stroke();

            if (progress >= 100) {
                clearInterval(animation);
                vizStatus.textContent = 'Secure';
                setTimeout(() => { vizStatus.textContent = 'Idle'; }, 1500);
            }
        }, 20);
    }

    // --- API Functions ---
    async function fetchCurrentUser() {
        const response = await fetch('/api/get_current_user');
        const data = await response.json();
        currentUser = data.username;
        currentUserDisplay.textContent = currentUser;
    }

    async function fetchUsers() {
        const response = await fetch('/api/get_users');
        const users = await response.json();
        userList.innerHTML = '';
        users.forEach(user => {
            if (user.username !== currentUser) {
                const li = document.createElement('li');
                li.textContent = user.username;
                li.dataset.username = user.username;
                userList.appendChild(li);
            }
        });
    }

    async function fetchMessages(recipient) {
        if (!recipient) return;
        const response = await fetch(`/api/get_messages?recipient=${recipient}`);
        const messages = await response.json();
        displayMessages(messages);
    }

    async function sendMessage(recipient, message) {
        if (!recipient || !message) return;
        playEncryptionAnimation('encrypt');
        await fetch('/api/send_message', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ recipient, message_text: message }),
        });
        messageInput.value = '';
        fetchMessages(recipient);
    }

    // --- UI Functions ---
    function displayMessages(messages) {
        messageDisplay.innerHTML = '';
        // Reverse to show newest at the bottom, but append in correct order
        messages.slice().reverse().forEach(msg => {
            const msgDiv = document.createElement('div');
            msgDiv.classList.add('message');
            msgDiv.textContent = msg.message_text;
            if (msg.sender === currentUser) {
                msgDiv.classList.add('sent');
            } else {
                msgDiv.classList.add('received');
                // Play decryption animation only for new messages, simple check
                if (new Date(msg.timestamp) > new Date(Date.now() - 5000)) {
                    playEncryptionAnimation('decrypt');
                }
            }
            messageDisplay.appendChild(msgDiv);
        });
    }

    // --- Event Listeners ---
    userList.addEventListener('click', (e) => {
        if (e.target && e.target.nodeName === 'LI') {
            document.querySelectorAll('#user-list li').forEach(li => li.classList.remove('active'));
            e.target.classList.add('active');
            selectedUser = e.target.dataset.username;
            recipientInput.value = selectedUser;

            clearInterval(messagePollingInterval);
            fetchMessages(selectedUser);
            messagePollingInterval = setInterval(() => fetchMessages(selectedUser), 3000);
        }
    });

    messageForm.addEventListener('submit', (e) => {
        e.preventDefault();
        sendMessage(selectedUser, messageInput.value);
    });

    // --- Initialization ---
    async function init() {
        await fetchCurrentUser();
        await fetchUsers();
    }

    init();
});
