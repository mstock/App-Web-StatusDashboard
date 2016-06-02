(function () {
	'use strict';

	angular.module('StatusDashboard', [
		'ngMessages',
		'ngWebSocket',
		'ngMessageFormat',
		'chart.js',
		'angularMoment',
		'ui.bootstrap'
	]).service('statusService', [
		'$http',
		'$websocket',
		'websocketUri',
		'$log',
		function ($http, $websocket, websocketUri, $log) {
			var status = {};

			var dataStream = $websocket(websocketUri);
			dataStream.onError(function (error) {
				$log.error("WebSocket error: ", error);
			});
			dataStream.onClose(function (message) {
				$log.debug("Connection closed: ", message);
				dataStream.reconnect();
			});
			dataStream.onMessage(function(message) {
				var data = JSON.parse(message.data);
				Object.keys(data).forEach(function (key) {
					status[key] = data[key];
				});
			});

			return {
				getStatus: function (serviceId) {
					return (status && serviceId && serviceId in status)
						? status[serviceId].data
						: null;
				},
				getLastUpdated: function (serviceId) {
					return (status && serviceId && serviceId in status)
						? status[serviceId].last_updated
						: null;
				}
			};
		}
	]).directive('statusDisplay', [
		'statusService',
		'moment',
		function (statusService, moment) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.$watch(
						function() {
							return statusService.getLastUpdated(scope.statusId)
						},
						function(newValue, oldValue) {
							if (newValue === null) {
								return;
							}
							scope.lastUpdated = moment(newValue);
						}
					);
				},
				replace:     false,
				templateUrl: 'app/templates/status-display.html',
				scope:       {
					statusTitle: '@statusTitle',
					statusId:    '@statusId'
				},
				transclude:  true
			}
		}
	]);
})();
