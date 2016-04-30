(function () {
	'use strict';

	angular.module('StatusDashboard', [
		'ngMessages',
		'ngWebSocket',
		'ngMessageFormat',
		'chart.js'
	]).service('statusService', [
		'$http',
		'$websocket',
		'websocketUri',
		function ($http, $websocket, websocketUri) {
			var status = {};

			var dataStream = $websocket(websocketUri);
			dataStream.onMessage(function(message) {
				var data = JSON.parse(message.data);
				Object.keys(data).forEach(function (key) {
					status[key] = data[key];
				});
			});

			return {
				getServiceStatus: function (serviceId) {
					return (status && serviceId && serviceId in status)
						? status[serviceId].data
						: null;
				}
			};
		}
	]).directive('statusDisplay', [
		'statusService',
		function (statusService) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {

				},
				replace:     false,
				templateUrl: 'app/templates/status-display.html',
				scope:       {
					title:       '@title',
					titlePrefix: '@titlePrefix',
					statusId:    '@statusId'
				},
				transclude:  true
			}
		}
	]);
})();
